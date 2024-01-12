#!/bin/bash
script_name=$0

#A script to project volumetric data to freesurfer-generated native cortical surfaces and the fsaverage surface at varying projection fractions or cortical depths
usage() {
	cat << EOF >&2
Usage: $script_name [-s] [-m] [-i] [-f] [-c] [-r] [-l] [-p] [-d] [-u]

-s <subject_id>: The subject identifier. This is the subject's directory name in the freesurfer SUBJECTS_DIR (i.e., the identifier used with --s in freesurfer commands; for longitudinal freesurfer output this would be <subject>_<session>.long.<subject>
-m <moving_image>: Full path to the volumetric file to use for registration to the subject's freesurfer-generated T1.mgz image
-i <input_image>: Full path to the volumetric file to project onto a subject's native freesurfer cortical surface and the fsaverage surface
-f <freesurfer_dir>: The freesurfer SUBJECTS_DIR. The directory freesurfer_dir/subject_id must exist with typical freesurfer outputs mri/ surf/ label/ etc.
-c <freesurfer_sif>: Full path to the singularity SIF container with the freesurfer version used to create the data in freesurfer_dir
-r <registration_dof>: Registration dof: 6, 9, or 12 [default 6]
-l <freesurfer_license>: Full path to a freesurfer license.txt
-p <projection_fraction>: The fractional depth of the cortical surface, between the GM-WM boundary and the pial surface, to project values to the surface from. 0.5 samples the middle of the cortical surface. Negative values project into the white matter. Can accept a comma separated list of values [default option; default value = 0.5]
-d <projection_distance>: The distance (in mm) between the GM-WM boundary and the pial surface to project values to the surface from. This projects the specified distance at all points on the surface regardless of the total thickness. Negative values project mm into the white matter. Can accept a comma separated listed of value [default = turned off]
-u <smoothing_fwhm>: The fwhm (in mm) to use for surface-based smoothing of the cortical data. If the smoothing_fwhm option is supplied, it will write out both unsmoothed and smoothed metric files. Can accept a comma separated list of values to smooth at varying fwhm [default = no smoothing applied]

Note, ensure the fsaverage subjects directory exists in freesurfer_dir before running 
EOF

	exit 1
}

subject_id=${SUBJECT_ID:-false}
moving_image=${MOVING_IMAGE:-false}
input_image=${INPUT_IMAGE:-false}
freesurfer_dir=${FS_DIR:-false}
freesurfer_sif=${FS_SIF:-false}
registration_dof=${REG_DOF:-6}
freesurfer_license=${LIC:-false}
projection_fraction=${PROJ_FRAC:-0.5}
projection_distance=${PROJ_DIST:-false}
smoothing_fwhm=${SMOOTH:-false}

while getopts "s:m:i:f:c:r:l:p:d:u:" opt; do
	case $opt in 
		(s) subject_id=$OPTARG;;
		(m) moving_image=$OPTARG;;
		(i) input_image=$OPTARG;;
		(f) freesurfer_dir=$OPTARG;;
		(c) freesurfer_sif=$OPTARG;;
		(r) registration_dof=$OPTARG;;
		(l) freesurfer_license=$OPTARG;;
		(p) projection_fraction=$OPTARG;;
		(d) projection_distance=$OPTARG;;
		(u) smoothing_fwhm=$OPTARG;;
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
if [[ "$projection_distance" =~ false ]] ; then #projection fraction (% pial-GM/WM boundary) mode
for hemi in lh rh; do
	for depth in ${projection_fraction//,/ }; do
		singularity exec --writable-tmpfs -B $input_image_dir:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /input/$input_image_name --hemi $hemi --projfrac $depth --srcreg /opt/freesurfer/subjects/$subject_id/mri/${moving_image_basename}_coreg_T1.lta --out /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}%.mgh
		if [[ "$smoothing_fwhm" != false ]] ; then #smoothed outputs requested
			for fwhm in ${smoothing_fwhm//,/ }; do
				singularity exec --writable-tmpfs -B $input_image_dir:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mris_fwhm --i /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}%.mgh --o /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}%.fwhm${fwhm}.mgh --s $subject_id --so --hemi ${hemi} --fwhm ${fwhm}
			done
		fi
	done
done
fi

if [[ "$projection_distance" != false ]] ; then #projection distance (mm) mode
for hemi in lh rh; do
	for depth in ${projection_distance//,/ }; do
		singularity exec --writable-tmpfs -B $input_image_dir:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /input/$input_image_name --hemi $hemi --projdist $depth --srcreg /opt/freesurfer/subjects/$subject_id/mri/${moving_image_basename}_coreg_T1.lta --out /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}mm.mgh
		if [[ "$smoothing_fwhm" != false ]] ; then #smoothed outputs requested
                        for fwhm in ${smoothing_fwhm//,/ }; do
                                singularity exec --writable-tmpfs -B $input_image_dir:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mris_fwhm --i /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}mm.mgh --o /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}mm.fwhm${fwhm}.mgh --s $subject_id --so --hemi ${hemi} --fwhm ${fwhm}
			done
		fi
	done
done
fi

## Project the input image to the fsaverage surface
if [[ "$projection_distance" =~ false ]] ; then #projection fraction (% pial-GM/WM boundary) mode 
for hemi in lh rh; do
	for depth in ${projection_fraction//,/ }; do
		singularity exec --writable-tmpfs -B $input_image_dir:/input -B ${freesurfer_dir}:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /input/$input_image_name --hemi $hemi --projfrac $depth --srcreg /opt/freesurfer/subjects/$subject_id/mri/${moving_image_basename}_coreg_T1.lta --trgsubject fsaverage  --out /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}%.fsaverage.mgh
		if [[ "$smoothing_fwhm" != false ]] ; then #smoothed outputs requested
                        for fwhm in ${smoothing_fwhm//,/ }; do
                                singularity exec --writable-tmpfs -B $input_image_dir:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mris_fwhm --i  /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}%.fsaverage.mgh --o  /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}%.fwhm${fwhm}.fsaverage.mgh --s fsaverage --so --hemi ${hemi} --fwhm ${fwhm}
			done
		fi
	done
done
fi

if [[ "$projection_distance" != false ]] ; then #projection distance (mm) mode 
for hemi in lh rh; do
	for depth in ${projection_distance//,/ }; do
		singularity exec --writable-tmpfs -B $input_image_dir:/input -B ${freesurfer_dir}:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2surf --src /input/$input_image_name --hemi $hemi --projdist $depth --srcreg /opt/freesurfer/subjects/$subject_id/mri/${moving_image_basename}_coreg_T1.lta --trgsubject fsaverage  --out /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}mm.fsaverage.mgh
		if [[ "$smoothing_fwhm" =~ false ]] ; then #smoothed outputs requested
                        for fwhm in ${smoothing_fwhm//,/ }; do
                                singularity exec --writable-tmpfs -B $input_image_dir:/input -B $freesurfer_dir:/opt/freesurfer/subjects -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mris_fwhm --i /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}mm.fsaverage.mgh --o /opt/freesurfer/subjects/$subject_id/surf/${hemi}.${input_image_type}.${depth}mm.fwhm${fwhm}.fsaverage.mgh --s fsaverage --so --hemi ${hemi} --fwhm ${fwhm}
			done
		fi
	done
done
fi
