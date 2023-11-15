#!/bin/bash
script_name=$0

# A script to project volumetric data to freesurfer-generated native cortical surfaces and the fsaverage surface at varying projection fractions (i.e., varying cortical depths)
## Note: copy fsaverage from freesurfer 7.4.1 into the freesurfer_dir before running on rhea
usage() {
	cat << EOF >&2
Usage: $script_name [-s] [-m] [-i] [-f] [-c] [-r] [-l] [-p]

-s <subject_id>: The subject identifier. This is the subject's directory name in the freesurfer SUBJECTS_DIR (i.e., the identifier used with --s in freesurfer commands; for longitudinal freesurfer output this would be <subject>_<session>.long.<subject>
-m <moving_image>: Full path to the volumetric file to use for registration to the subject's freesurfer-generated T1.mgz image
-i <input_image>: Full path to the volumetric file to project onto a subject's native freesurfer cortical surface and the fsaverage surface
-f <freesurfer_dir>: The freesurfer SUBJECTS_DIR. The directory freesurfer_dir/subject_id must exist with typical freesurfer outputs mri/ surf/ label/ etc.
-c <freesurfer_sif>: Full path to the singularity SIF container with the freesurfer version used to create the data in freesurfer_dir
-r <registration_dof>: Registration dof: 6, 9, or 12 [default 6]
-l <freesurfer_license>: Full path to a freesurfer license.txt
-p <projection_depth>: The depth of the cortical surface, between the GM-WM boundary (0) and the pial surface (1), to project values to the surface from. 0.5 samples the middle of the cortical surface. Negative values project into the white matter. Can accept a comma separated list of values [default 0.5] 
EOF

	exit 1
}

subject_id=false
moving_image=false
input_image=false
freesurfer_dir=false
freesurfer_sif=false
registration_dof=6
freesurfer_license=false
projection_depth=0.5

while getopts "s:m:i:f:c:r:l:p:" opt; do
	case $opt in 
		(s) subject_id=$OPTARG;;
		(m) moving_image=$OPTARG;;
		(i) input_image=$OPTARG;;
		(f) freesurfer_dir=$OPTARG;;
		(c) freesurfer_sif=$OPTARG;;
		(r) registration_dof=$OPTARG;;
		(l) freesurfer_license=$OPTARG;;
		(p) projection_depth=$OPTARG;;
		 *) usage;;
	esac

	case $OPTARG in
		-) echo "Command line argument $opt needs a valid argument"
		exit 1 ;;
	esac
done

if [[ "$subject_id $moving_image $input_image $freesurfer_dir $freesurfer_sif $freesurfer_license" =~ false ]] ; then
	echo "$0 call is missing one of: -s -m -i -f -c -l"
	usage
	exit 1
fi

## Get input for this run
moving_image_name=$(basename ${moving_image})
moving_image_basename=$(basename ${moving_image/.nii.gz/})
moving_image_dir=$(dirname $moving_image)
input_image_name=$(basename ${input_image})
input_image_basename=$(basename ${input_image/.nii.gz/})
input_image_type=$(echo ${input_image_basename} | cut -f1,2 -d'_' --complement)
input_image_dir=$(dirname $input_image)

## Register the moving_image to the subject's freesurfer-generated T1.mgz and save the lta transform file
singularity exec --writable-tmpfs -B $moving_image_dir:/moving -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_coreg --sd /opt/freesurfer/subjects --s $subject_id --mov /moving/$moving_image_name --ref /opt/freesurfer/subjects/$subject_id/mri/T1.mgz --reg /opt/freesurfer/subjects/$subject_id/mri/${moving_image_basename}_coreg_T1.lta --dof $registration_dof

## Project the input_image to the subject's freesurfer-generated native cortical surface 
for hemi in lh rh; do
	for depth in ${projection_depth//,/ }; do
		singularity exec --writable-tmpfs -B $input_image_dir:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /input/$input_image_name --hemi $hemi --projfrac $depth --srcreg /opt/freesurfer/subjects/$subject_id/mri/${moving_image_basename}_coreg_T1.lta --out /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}depth.mgh
	done
done
## Project the input image to the fsaverage surface
for hemi in lh rh; do
	for depth in ${projection_depth//,/ }; do
		singularity exec --writable-tmpfs -B $input_image_dir:/input -B ${freesurfer_dir}:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /input/$input_image_name --hemi $hemi --projfrac $depth --srcreg /opt/freesurfer/subjects/$subject_id/mri/${moving_image_basename}_coreg_T1.lta --trgsubject fsaverage  --out /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}depth.fsaverage.mgh
	done
done

