#!/usr/bin/env bash

#A script to run collect_stats_to_tsv.sh on individual sessions via job submission on the PSC. These jobs will create cortex pve maps in fsaverage and fslr-32k surfaces and compute depth-dependent cortex pve metrics in atlases of interest 

#Set up global environment variables required as command line inputs
project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
neuromaps_sif=${project_dir}/software/neuromaps-0.0.4.sif
license=${project_dir}/software/license.txt
output_base=${project_dir}/BIDS/derivatives/cortexpve_metrics
anatomical_stats=false
vertices=32k
script_dir=${project_dir}/code/corticalmyelin_maturation/surface_metrics/fstabulate

export project_dir freesurfer_dir freesurfer_sif neuromaps_sif license output_base anatomical_stats vertices

script_dir="$(cd "$(dirname "$0")"||:; pwd)"

#Loop through session-specific longitudinal freesurfer subject ids to submit collect_stats_to_tsv.sh as a job for each session 
for subject_id in $freesurfer_dir/sub*ses*.long.sub*; do
	subject_id=$(basename ${subject_id})
	subses=${subject_id%%.*}
	sub=${subses%_*}
	ses=${subses#*_}
	mkdir -p $output_base/$sub/$ses
	output_dir=$output_base/$sub/$ses

   #Don't submit this subject's job if its already running
   squeue |grep "${subses}-cortexpve" && continue

   #Launch job via sbatch
	sbatch \
      -J "${subses}-cortexpve" \
      --time 00:30:00 \
      -p RM-shared \
      --nodes 1 \
      --ntasks-per-node 1  \
      -o "${subses}-fstabulate-cortexpve.o" \
      -e "${subses}-fstabulate-cortexpve.e" \
      --export="ALL,SUBJECT_ID=$subject_id,FS_DIR=$freesurfer_dir,FS_SIF=$freesurfer_sif,NM_SIF=$neuromaps_sif,LIC=$license,OUTPUT_DIR=$output_dir,'METRICS=cortexpve.0.0%,cortexpve.0.1%,cortexpve.0.2%,cortexpve.0.3%,cortexpve.0.4%,cortexpve.0.5%,cortexpve.0.6%,cortexpve.0.7%,cortexpve.0.8%,cortexpve.0.9%,cortexpve.1.00%','PARCS=glasser,Schaefer2018_400Parcels_17Networks_order,EEGatlas','NATIVE=none',ANAT=$anatomical_stats,VERTICES=$vertices,SCRIPTDIR=$script_dir" \
      "$script_dir/collect_stats_to_tsv.sh"
done	
