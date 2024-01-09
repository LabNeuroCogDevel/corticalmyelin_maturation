#!/bin/bash

#A script to organize the output of SPM's UNICORT run on raw quantitative T1 images

BIDS_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
unicort_T1dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/unicort_T1map
participant_file=/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_CuBIDS_subses_list.txt 

while read line; do
	subses=$line
	subject_id=${subses% *}
	session_id=${subses#* }
	echo "cleaning up UNICORT output for $subject_id $session_id"
		
	#Rename and gzip the UNICORT-corrected quantitative T1 image
	cp ${unicort_T1dir}/${subject_id}/${session_id}/anat/m${subject_id}_${session_id}_T1map.nii ${unicort_T1dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_T1map-corrected.nii
	gzip ${unicort_T1dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_T1map-corrected.nii		
	#Make sure there is a matching json file
	cp ${unicort_T1dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_T1map.json ${unicort_T1dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_T1map-corrected.json 	
        #Clean up unnecesary files
	rm ${unicort_T1dir}/${subject_id}/${session_id}/anat/*acq-UNIDENT1corrected_T1w*
	rm ${unicort_T1dir}/${subject_id}/${session_id}/anat/*acq-UNIDENT1*
	rm ${unicort_T1dir}/${subject_id}/${session_id}/anat/*inv*part*
	rm ${unicort_T1dir}/${subject_id}/${session_id}/anat/*UNIT1.json
	rm ${unicort_T1dir}/${subject_id}/${session_id}/anat/*UNIT1.nii
	rm ${unicort_T1dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_T1map.nii
	rm ${unicort_T1dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_T1map.json

done < ${participant_file}	

