#!/bin/bash

# A script to run longitudinal_freesurfer_call.sh on individual participants through qsub submissions

project_dir= #project directory on the cluster
subject_list= #list of subjects with denoised UNI data
bids_dir=${project_dir}/BIDS
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer
freesurfer_container=${project_dir}/software/freesurfer-7.4.1.sif 
freesurfer_license=${project_dir}/software/license.txt

for sub in $(cat ${subject_list}); do
	qsub -N ${sub}-fs-mp2rage -l h_vmem=32G,s_vmem=32G -pe smp 8 -S bash -o ${project_dir}/logs/freesurfer/${sub}-freesurfer7.4.1.o -e ${project_dir}/logs/freesurfer/${sub}-freesurfer7.4.1.e ${project_dir}/code/corticalmyelin_maturation/longitudinal_freesurfer/longitudinal_freesurfer_call.sh -s $sub -b $bids_dir -f $freesurfer_dir -c $freesurfer_container -l $freesurfer_license
done	
