#!/usr/bin/env bash

#A script to submit longitudinal_freesurfer_call.sh per BIDS subject id on the PSC

#Set up global environment variables required as command line inputs to longitudinal_freesurfer_call.sh
project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
bids_dir=${project_dir}/BIDS
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
license=${project_dir}/software/license.txt
acq_label=UNIDENT1corrected
cores=2
export bids_dir freesurfer_dir freesurfer_sif license acq_label cores

script_dir="$(cd "$(dirname "$0")"||:; pwd)"

#Loop through CuBIDS participant list to submit longitudinal_freesurfer_call.sh as a job for each subject (if no file present, glob through subject ids in BIDS)
participant_list=${project_dir}/sample_info/7T_CuBIDS_subjects_list.txt 
test -r "$participant_list" && 
   mapfile -t sublist < "${participant_list}" ||
   mapfile -t sublist < <(printf "%s\n" $project_dir/BIDS/sub-*|sed s:sub-::)

for subject_id in $(cat $participant_list); do

   #Don't submit this subject's job if its already running
   squeue |grep "${subject_id}-fsbids-7.4.1" && continue

   if ! [[ -d ${freesurfer_dir}/${subject_id} ]]; then
   #Launch job via sbatch
	sbatch \
      -J "${subject_id}-fsbids-7.4.1" \
      --time 48:00:00 \
      -p RM-shared \
      --nodes 1 \
      --ntasks-per-node ${cores} \
      -o "${subject_id}-freesurfer7.4.1.o" \
      -e "${subject_id}-freesurfer7.4.1.e" \
      --export="ALL,SUBJECT_ID=$subject_id,ACQ=$acq_label,BIDS_DIR=$bids_dir,FS_DIR=$freesurfer_dir,FS_SIF=$freesurfer_sif,LIC=$license,CORES=$cores" \
      "$script_dir/longitudinal_freesurfer_call.sh"
fi
done	
