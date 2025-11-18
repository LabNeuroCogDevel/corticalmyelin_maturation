#!/bin/bash

#A script to label each voxel in the frontal lobe (of R1 images) a different value and project voxel values to participant-specific cortical surfaces at varying projection fractions

project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
freesurfer_license=${project_dir}/software/license.txt
R1_dir=${project_dir}/BIDS/derivatives/R1maps

for fs_dir in $freesurfer_dir/sub*ses*.long.sub*; do
	fs_id=$(basename ${fs_dir})
	echo "Processing ${fs_id}"
	subses=${fs_id%%.*}
	subject_id=${subses%_*}
	session_id=${subses#*_}

	# Register R1 data to freesurfer T1.mgz using pre-computed lta files
	fs_input=${fs_dir}/mri
	fs_surf=${fs_dir}/surf
	R1_input=${R1_dir}/${subject_id}/${session_id}	

	singularity exec -B $freesurfer_dir:/opt/freesurfer/subjects -B $fs_input:/Freesurfer_input -B $R1_input:/R1_input -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2vol --mov /R1_input/${subject_id}_${session_id}_R1map.nii.gz --targ /Freesurfer_input/T1.mgz --lta /Freesurfer_input/${subject_id}_${session_id}_acq-UNIDENT1corrected_T1w_coreg_T1.lta --o /Freesurfer_input/${subject_id}_${session_id}_FScoreg_R1map.nii.gz 

	# Assign each voxel in R1 image a different integer value
	nx=$(/ocean/projects/soc230004p/shared/tools/afni/3dinfo -ni ${fs_input}/${subject_id}_${session_id}_FScoreg_R1map.nii.gz)
	ny=$(/ocean/projects/soc230004p/shared/tools/afni/3dinfo -nj ${fs_input}/${subject_id}_${session_id}_FScoreg_R1map.nii.gz)
	nz=$(/ocean/projects/soc230004p/shared/tools/afni/3dinfo -nk ${fs_input}/${subject_id}_${session_id}_FScoreg_R1map.nii.gz)

	/ocean/projects/soc230004p/shared/tools/afni/3dcalc -a ${fs_input}/${subject_id}_${session_id}_FScoreg_R1map.nii.gz -expr "i+1 + j*${nx} + k*${nx}*${ny}" -prefix ${fs_input}/${subject_id}_${session_id}_voxelwise_map.nii.gz

	# Create a participant (and timepoint) specific frontal lobe mask
	singularity exec -B $freesurfer_dir:/opt/freesurfer/subjects -B $fs_input:/Freesurfer_input -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_extract_label /Freesurfer_input/aparc+aseg.mgz 1002 1003 1012 1014 1018 1019 1020 1024 1026 1027 1028 1032 1035 2002 2003 2012 2014 2018 2019 2020 2024 2026 2027 2028 2032 2035 /Freesurfer_input/frontallobe.nii.gz #frontal lobe label values
	singularity exec -B $freesurfer_dir:/opt/freesurfer/subjects -B $fs_input:/Freesurfer_input -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_binarize --i /Freesurfer_input/frontallobe.nii.gz --o /Freesurfer_input/frontallobe.nii.gz --min 1 --binval 1 #binary mask
        
	# Get voxel values in only the frontal lobe
	singularity exec  -B $fs_input:/Freesurfer_input /ocean/projects/soc230004p/shared/datasets/7TBrainMech/software/qsiprep-1.0.0.simg fslmaths /Freesurfer_input/${subject_id}_${session_id}_voxelwise_map.nii.gz -mul /Freesurfer_input/frontallobe.nii.gz /Freesurfer_input/${subject_id}_${session_id}_voxelwise_frontalmap.nii.gz

	# Project frontal lobe voxel values to the cortical surface in 10% increments of cortical thickness
	projection_fraction=0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.00
	for hemi in lh rh; do
		for depth in ${projection_fraction//,/ }; do
			singularity exec -B $freesurfer_dir:/opt/freesurfer/subjects -B $fs_input:/Freesurfer_input -B $fs_surf:/Freesurfer_surf -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /Freesurfer_input/${subject_id}_${session_id}_voxelwise_frontalmap.nii.gz --hemi $hemi --projfrac $depth --regheader ${fs_id} --out /Freesurfer_surf/${hemi}.frontalvoxelmap.${depth}%.mgh --interp nearest
		done
	done
done



