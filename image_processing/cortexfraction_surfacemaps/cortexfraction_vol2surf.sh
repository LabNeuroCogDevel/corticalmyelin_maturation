#!/bin/bash

#A script to project cortex partial volume estimation to individual surfaces at varying projection fractions
project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
freesurfer_license=${project_dir}/software/license.txt
projection_fraction=0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.00

for subject_id in $freesurfer_dir/sub*ses*.long.sub*; do
	subject_id=$(basename ${subject_id})
	subses=${subject_id%%.*}
	input=${freesurfer_dir}/${subject_id}/mri
	
	for hemi in lh rh; do
		for depth in ${projection_fraction//,/ }; do
			singularity exec --writable-tmpfs -B $input:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /input/${subses}_cortex.nii.gz --hemi $hemi --projfrac $depth --regheader ${subject_id} --out /opt/freesurfer/subjects/${subject_id}/surf/${hemi}.cortexpve.${depth}%.mgh --interp nearest 
		done
	done
done
