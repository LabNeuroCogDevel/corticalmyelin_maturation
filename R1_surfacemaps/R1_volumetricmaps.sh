#!/bin/bash

#A script to create R1 (1/T1) volumetric maps

unicort_T1dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/unicort_T1map
R1dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/R1maps
participant_file=/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_CuBIDS_subses_list.txt

mkdir -p $R1dir

while read line; do
	subses=$line
	subject_id=${subses% *}
	session_id=${subses#* }
	echo "creating volumetric R1 map for $subject_id $session_id"
	mkdir -p ${R1dir}/${subject_id}/${session_id}
	
	#Convert T1 map from msec to sec
	3dcalc -a ${unicort_T1dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_T1map-corrected.nii.gz -expr 'a/1000' -prefix ${R1dir}/${subject_id}/${session_id}/${subject_id}_${session_id}_T1map_s.nii.gz
	#Compute R1 = 1/T1 (s^-1)
	3dcalc -a ${R1dir}/${subject_id}/${session_id}/${subject_id}_${session_id}_T1map_s.nii.gz  -expr '1/a' -prefix ${R1dir}/${subject_id}/${session_id}/${subject_id}_${session_id}_R1map.nii.gz

done < ${participant_file}



