#!/bin/bash

#A script to get MRSI ROIs in SPM-corrected MP2RAGE grid

BIDS_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
deriv_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/MRSI_regions
mkdir -p $deriv_dir

## Identify all final coords_mprage.nii.gz files (MRSI region placements in MP2RAGE slices, to be used for R1 quantification)
touch /Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/MRSI_regions/MRSI_coords_files.txt
readlink /Volumes/Hera/Projects/7TBrainMech/subjs/1*_2*/slice_PFC/MRSI_roi/LCModel/v2idxfix/13MP20200207_picked_coords.txt | sed s/picked_coords.txt$/coords_mprage.nii.gz/g >> /Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/MRSI_regions/MRSI_coords_files.txt #identify the scan-specific coords_mprage.nii.gz to use based on the best coordinate placements #but I am the chosen one

#Symlink and name the chosen coords_mprage.nii.gz files by the MRSI date to enable matching to MP2RAGE sub/ses UNIs
while read line ; do
	file=$line
	date=$(echo $file | grep -oP '\b\d{5}_\d{8}\b') #get the MRSI date from the file path
	ln -s $file ${deriv_dir}/mp2rage_coords/${date}_coords_mprage.nii.gz
done < /Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/MRSI_regions/MRSI_coords_files.txt

#3dresample the coords_mprage.nii.gz files to match the master SPM-corrected MP2RAGE grid and output with MP2RAGE subject_id and session_id indicators
while read line; do
	file=$line
	mrsi_date=$(echo "$file" | cut -d ',' -f1)
	subject_id=$(echo "$file" | cut -d ',' -f2)
	session_id=$(echo "$file" | cut -d ',' -f3)
	if [[ $mrsi_date =~ [0-9] ]]; then 
		mkdir -p ${deriv_dir}/${subject_id}/${session_id}
		3dresample -rmode NN -master ${BIDS_dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_acq-UNIDENT1corrected_T1w.nii.gz -inset ${deriv_dir}/mp2rage_coords/${mrsi_date}_coords_mprage.nii.gz -prefix ${deriv_dir}/${subject_id}/${session_id}/${subject_id}_${session_id}_MRSIregions.nii.gz
	fi
done < /Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MRSIdate_subses_idkey.csv #mrsi_date, subject_id, session_id matching key csv
