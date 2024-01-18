#!/usr/bin/env bash

#A script to run collect_stats_to_tsv.sh on individual sessions via job submission on the PSC. These jobs will derive anatomical stats and depth-dependent R1 in multiple cortical atlases as well as generate tar files with anatomical and R1 metrics in fsaverage and fslr-32k surfaces 

#Set up global environment variables required as command line inputs
project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
neuromaps_sif=${project_dir}/software/neuromaps-0.0.4.sif
license=${project_dir}/software/license.txt
output_base=${project_dir}/BIDS/derivatives/surface_metrics
anatomical_stats=true
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
   squeue |grep "${subses}-fstabulate" && continue

   #Launch job via sbatch
	sbatch \
      -J "${subses}-fstabulate" \
      --time 00:30:00 \
      -p RM-shared \
      --nodes 1 \
      --ntasks-per-node 1  \
      -o "${subses}-fstabulate-anatR1.o" \
      -e "${subses}-fstabulate-anatR1.e" \
      --export="ALL,SUBJECT_ID=$subject_id,FS_DIR=$freesurfer_dir,FS_SIF=$freesurfer_sif,NM_SIF=$neuromaps_sif,LIC=$license,OUTPUT_DIR=$output_dir,'METRICS=R1map.0.0%,R1map.0.1%,R1map.0.2%,R1map.0.3%,R1map.0.4%,R1map.0.5%,R1map.0.6%,R1map.0.7%,R1map.0.8%,R1map.0.9%,R1map.1.00%,w-g.pct','PARCS=glasser,gordon333dil,Juelich,Schaefer2018_400Parcels_17Networks_order,Schaefer2018_200Parcels_17Networks_order','NATIVE=aparc',ANAT=$anatomical_stats,VERTICES=$vertices,SCRIPTDIR=$script_dir" \
      "$script_dir/collect_stats_to_tsv.sh"
done	
