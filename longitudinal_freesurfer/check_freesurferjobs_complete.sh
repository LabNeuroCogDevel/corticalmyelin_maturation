#!/bin/bash

#A script to check whether longitudinal freesurfer (launched with freesurfer_submitjobs_PSC.sh) ran successfully on all subejcts and sessions

project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
subseslist=${project_dir}/sample_info/7T_CuBIDS_subses_list.txt

if [[ -f ${freesurfer_dir}/longitudinal_freesurfer_complete.txt ]]; then
	rm ${freesurfer_dir}/longitudinal_freesurfer_complete.txt
	touch ${freesurfer_dir}/longitudinal_freesurfer_complete.txt
fi

while read line ; do
	subject_id=$(echo $line | awk '{print $1}')
	session_id=$(echo $line | awk '{print $2}')
	reconlog=$(tail -n 1 ${freesurfer_dir}/${subject_id}_${session_id}.long.${subject_id}/scripts/recon-all.log)
	if [[ -d ${freesurfer_dir}/${subject_id}_${session_id}.long.${subject_id} ]] & [[ -f ${freesurfer_dir}/${subject_id}_${session_id}.long.${subject_id}/surf/lh.white ]] & [[ -f ${freesurfer_dir}/${subject_id}_${session_id}.long.${subject_id}/surf/rh.white ]] & [[ -f ${freesurfer_dir}/${subject_id}_${session_id}.long.${subject_id}/stats/wmparc.stats ]] & [[ $reconlog == *"finished without error"* ]] ; then
		echo ${subject_id}_${session_id}.long.${subject_id} >> ${freesurfer_dir}/longitudinal_freesurfer_complete.txt
	else
		echo ${subject_id}_${session_id}.long.${subject_id} >> ${freesurfer_dir}/longitudinal_freesurfer_failed.txt
	fi
done < $subseslist

