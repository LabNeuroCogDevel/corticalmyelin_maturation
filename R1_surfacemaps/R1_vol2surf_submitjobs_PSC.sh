#!/usr/bin/env bash

#A script to run voltosurf_projection_nativefsaverage.sh on individual sessions via job submission on the PSC

#Set up global environment variables required as command line inputs
project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
license=${project_dir}/software/license.txt
registration_dof=6

export project_dir freesurfer_dir freesurfer_sif license regionstration_dof

script_dir="$(cd "$(dirname "$0")"||:; pwd)"

#Loop through session-specific longitudinal freesurfer subject ids to submit voltosurf_projection_nativefsaverage.sh as a job for each session 
for subject_id in $freesurfer_dir/sub*ses*.long.sub*; do
	subject_id=$(basename ${subject_id})
	subses=${subject_id%%.*}
	sub=${subses%_*}
	ses=${subses#*_}
	moving_image=${project_dir}/BIDS/${sub}/${ses}/anat/${subses}_acq-UNIDENT1corrected_T1w.nii.gz
	input_image=${project_dir}/BIDS/derivatives/R1maps/${sub}/${ses}/${subses}_R1map.nii.gz
   
   #Don't submit this subject's job if its already running
   squeue |grep "${subses}-R1-vol2surf" && continue

   #Launch job via sbatch
	sbatch \
      -J "${subses}-R1-vol2surf" \
      --time 00:30:00 \
      -p RM-shared \
      --nodes 1 \
      --ntasks-per-node 1  \
      -o "${subses}-R1-vol2surf.o" \
      -e "${subses}-R1-vol2surf.e" \
      --export="ALL,SUBJECT_ID=$subject_id,MOVING_IMAGE=$moving_image,INPUT_IMAGE=$input_image,FS_DIR=$freesurfer_dir,FS_SIF=$freesurfer_sif,REG_DOF=$registration_dof,LIC=$license,'PROJ_FRAC=0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.00','SMOOTH=1,5'" \
      "$script_dir/voltosurf_projection_nativefsaverage.sh"
done	
