#!/bin/bash

#A script to compute partial volume fractions for cortex (and other tissues/CSF) using freesurfer's mri_compute_volume_fractions
project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
freesurfer_license=${project_dir}/software/license.txt

#Loop through session-specific longitudinal freesurfer subject ids and call mri_compute_volume_fractions
for subject_id in $freesurfer_dir/sub*ses*.long.sub*; do
	subject_id=$(basename ${subject_id})
	subses=${subject_id%%.*}
	subject_fs=${freesurfer_dir}/${subject_id}/mri
	if ! [[ -f ${subject_fs}/${subses}_cortex.nii.gz ]] ; then
		singularity exec --writable-tmpfs -B $subject_fs:/output -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_compute_volume_fractions --o /output/${subses} --regheader ${subject_id} /output/norm.mgz
		singularity exec --writable-tmpfs -B $subject_fs:/output -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_convert /output/${subses}.cortex.mgz /output/${subses}_cortex.nii.gz
	fi
done	
