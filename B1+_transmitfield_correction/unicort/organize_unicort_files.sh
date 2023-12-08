#!/bin/bash
#
#A script to organize the output of SPM's UNICORT run on UNI images, including copying the inhomogeneity corrected UNI image to BIDS/ for freesurfer and deleting redundant files the software copies from BIDS/ to output/

BIDS_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
unicort_UNIdir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/unicort_UNI
participant_file=/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_CuBIDS_subses_list.txt 

while read line; do
	subses=$line
	subject_id=${subses% *}
	session_id=${subses#* }
	#Bring the corrected UNI image to BIDS_dir for further analysis with BIDS-apps
	cp ${unicort_UNIdir}/${subject_id}/${session_id}/anat/m${subject_id}_${session_id}_acq-UNIDENT1_T1w.nii ${BIDS_dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_acq-UNIDENT1corrected_T1w.nii
	gzip ${BIDS_dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_acq-UNIDENT1corrected_T1w.nii
	#Make sure there is a matching json file
	cp ${BIDS_dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_acq-UNIDENT1_T1w.json ${BIDS_dir}/${subject_id}/${session_id}/anat/${subject_id}_${session_id}_acq-UNIDENT1corrected_T1w.json  	
        #Clean up unnecesary files
	rm ${unicort_UNIdir}/${subject_id}/${session_id}/anat/sub*nii 
        rm ${unicort_UNIdir}/${subject_id}/${session_id}/anat/sub*json
done < ${participant_file}	

