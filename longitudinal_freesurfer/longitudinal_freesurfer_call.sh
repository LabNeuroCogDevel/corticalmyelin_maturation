#!/bin/bash
script_name=$0

# A script to run longitudinal freesurfer with the freesurfer bids-app singularity container on individual participants. Runs all stages of recon-all as well as cross-sectional, template, and longitudinal steps for all BIDS sessions

usage() {
        cat << EOF >&2
Usage: $script_name [-s] [-a] [-b] [-f] [-c] [-l] [-r]

-s <subject_id>: The subject identifier. This is the top-level BIDS sub-id
-a <acquisition_label>: If the input BIDS dataset contains multiple _T1w images from different acquisitions, the BIDS -acq-<acquisition_label> label can be supplied to specify which T1w image to freesurfer. Optional argument 
-b <bids_directory>: Full path to the BIDS directory containing the <subject_id> folder
-f <freesurfer_directory>: The freesurfer directory where output files should be stored
-c <freesurfer_sif>: Full path to the singularity SIF container with the freesurfer bids-app
-l <freesurfer_license>: Full path to a freesurfer license.txt
-r <rerun>: If freesurfer output already exists for this <subject_id>, should it be rerun? Setting rerun to TRUE will delete all subject-specific output directories in <freesurfer_directory> to enable a rerun. Defaults to FALSE
EOF

        exit 1
}

subject_id=${SUBJECT_ID:-false}
bids_dir=${BIDS_DIR:-false}
freesurfer_dir=${FS_DIR:-false}
freesurfer_sif=${FS_SIF:-false}
freesurfer_license=${LIC:-false}
acquisition_label=FALSE
rerun=FALSE

while getopts "s:a:b:f:c:l:r:" opt; do
        case $opt in 
                (s) subject_id=$OPTARG;;
		(a) acquisition_label=$OPTARG;;
		(b) bids_dir=$OPTARG;;
		(f) freesurfer_dir=$OPTARG;;
                (c) freesurfer_sif=$OPTARG;;
                (l) freesurfer_license=$OPTARG;;
		(r) rerun=$OPTARG;;
                 *) usage;;
        esac

        case $OPTARG in
                -) echo "Command line argument $opt needs a valid argument"
                exit 1 ;;
        esac
done

if [[ "$subject_id $bids_dir $freesurfer_dir $freesurfer_sif $freesurfer_license" =~ false ]] ; then
        echo "$0 call is missing one of: -s -b -f -c -l"
        usage
        exit 1
fi
if [[ ${rerun} != "FALSE" ]] && [[ ${rerun} != "TRUE" ]] ; then
	echo "-r must be one of: TRUE, FALSE"
	exit 1
fi

# Get input for this run
## check whether output already exists for this subject, and whether it should be deleted to enable a rerun if it does
if [[ -d ${freesurfer_dir}/${subject_id} ]] && [[ ${rerun} == TRUE ]] ; then
	rm -Rf ${freesurfer_dir}/*${subject_id}*
fi
## remove "sub-" from the subject_id if provided, bids/freesurfer participant label should not include sub-
if [[ ${subject_id} == *"sub"* ]] ; then
	subject_id=${subject_id#"sub-"}
fi
## create output directory if it does not exist
if ! [[ -d ${freesurfer_dir} ]] ; then
	mkdir $freesurfer_dir
fi

# Singularity call to the bids-app
## typical call
if [[ ${acquisition_label} == "FALSE" ]] ; then
	singularity run -B ${bids_dir}:/BIDS -B ${freesurfer_dir}:/Freesurfer_output -B ${freesurfer_license}:/license.txt $freesurfer_sif /BIDS /Freesurfer_output participant --participant_label ${subject_id} --license_file /license.txt --stages all --steps {cross-sectional,template,longitudinal} --multiple_sessions longitudinal --skip_bids_validator
fi
## specialized call to specify a BIDS T1w acquisition label
if [[ ${acquisition_label} != "FALSE" ]] ; then
	singularity run -B ${bids_dir}:/BIDS -B ${freesurfer_dir}:/Freesurfer_output -B ${freesurfer_license}:/license.txt $freesurfer_sif /BIDS /Freesurfer_output participant --participant_label ${subject_id} --acquisition_label ${acquisition_label} --license_file /license.txt --stages all --steps {cross-sectional,template,longitudinal} --multiple_sessions longitudinal --skip_bids_validator
fi
