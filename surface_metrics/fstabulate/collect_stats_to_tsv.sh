#!/bin/bash

script_name=$0

# A script that will calculate desired surface metrics for a list of surface atlases
# and will grab subject metadata. Creates stat tsv and json files of the results.
# Also creates cifti dscalar.nii files for desired surface metrics at requested vertex density.

usage() {
	cat << EOF >&2
Usage: $script_name [-s] [-f] [-c] [-n] [-l] [-o] [-m] [-p] [-d] [-a] [-v]

-s <subject_id>: The subject identifier. This is the subject's directory name in the freesurfer 
SUBJECTS_DIR (i.e., the identifier used with --s in freesurfer commands) (positional arg)

-f <freesurfer_dir>: The freesurfer SUBJECTS_DIR. The directory <freesurfer_dir>/<subject_id> 
must exist with typical freesurfer outputs mri/ surf/ label/ etc. (positional arg)

-c <freesurfer_sif>: Full path to the singularity SIF container with freesurfer. This should 
be the exact version of freesurfer that was used to create the data in freesurfer_dir. Can be 
a freesurfer.sif or fmriprep.sif (positional arg)

-n <neuromaps_sif>: Full path to a singularity container for neuromaps, used for the creation 
of cifti metric files (positional arg)

-l <freesurfer_license>: Full path to a freesurfer license.txt (positional arg)

-o <output_dir>: Path to where the output files will go (positional arg)

-m <metrics>: A comma separated list of metrics to generate stats and ciftis for, in addition to 
the metrics automatically calculated by mris_anatomical_stats (number of vertices, surface area, 
gray matter volume, average thickness, thickness std, mean curvature, gaussian curvative, folding 
index). Metrics can include freesurfer-generated metrics w-g.pct, sulc, pial_lgi, and/or 
user-specified measure(s). The user-specified measure(s) must have been projected onto both the 
subject's native surface and the fsaverage surface (with e.g. mri_vol2surf and mri_surf2surf) and 
must exist as .mgh files in <freesurfer_dir>/<subject_id>/surf in the format $hemi.<metric>.mgh 
and $hemi.<metric>.fsaverage.mgh, respectively. If no additional metrics are of interest, can 
be left blank (defaults to none) 

-p <parcellations>: A comma separated list of non-freesurfer-native parcellations to compute stats 
for. Parcellations can include any of the annot files found in fstabulate/annots 
(e.g., glasser, Juelich, Schaefer2018_400Parcels_7Networks_order) or can be set to "none". If
 left blank, defaults to all

-d <native_parcellations>: A comma separated list of atlases that come with freesurfer and
exist in fsnative (aparc.DKTatlas, aparc.a2009s, aparc, BA_exvivo) or can be set to "none".
If left blank, defaults to all

-a <anatomical_stats>: Whether to run mris_anatomical_stats and output typical anatomical stats
files and ciftis if user-supplied -m <metrics> are also requested. Must be a value of "true" or 
"false" (defaults to true) 

-v <vertices>: The vertex density to write out cifti surface metrics at. Can be 32k or 164k 
(defaults to 32k)

EOF

	exit 1
}

subject_id=${SUBJECT_ID:-false} # positional argument
freesurfer_dir=${FS_DIR:-false} # positional argument
freesurfer_sif=${FS_SIF:-false} # positional argument
neuromaps_sif=${NM_SIF:-false} # positional argument
freesurfer_license=${LIC:-false} # positional argument
output_dir=${OUTPUT_DIR:-false} # positional argument
metrics=${METRICS:-none} # user can specify a list of additional metrics, but defaults to none
parcellations=${PARCS:-AAL,CC200,CC400,glasser,gordon333dil,HOCPATh25,Juelich,PALS_B12_Brodmann,Schaefer2018_1000Parcels_17Networks_order,Schaefer2018_1000Parcels_7Networks_order,Schaefer2018_100Parcels_17Networks_order,Schaefer2018_100Parcels_7Networks_order,Schaefer2018_200Parcels_17Networks_order,Schaefer2018_200Parcels_7Networks_order,Schaefer2018_300Parcels_17Networks_order,Schaefer2018_300Parcels_7Networks_order,Schaefer2018_400Parcels_17Networks_order,Schaefer2018_400Parcels_7Networks_order,Schaefer2018_500Parcels_17Networks_order,Schaefer2018_500Parcels_7Networks_order,Schaefer2018_600Parcels_17Networks_order,Schaefer2018_600Parcels_7Networks_order,Schaefer2018_700Parcels_17Networks_order,Schaefer2018_700Parcels_7Networks_order,Schaefer2018_800Parcels_17Networks_order,Schaefer2018_800Parcels_7Networks_order,Schaefer2018_900Parcels_17Networks_order,Schaefer2018_900Parcels_7Networks_order,Slab,Yeo2011_17Networks_N1000,Yeo2011_7Networks_N1000} # user can specify a list of parcellations, but defaults to all
native_parcellations=${NATIVE:-aparc.DKTatlas,aparc.a2009s,aparc,BA_exvivo} # user can specify a list of fs native parcellations, but defaults to all
anatomical_stats=${ANAT:-true} # user can toggle mris_anatomical stats on or off, but it is run by default
vertices=${VERTICES:-32k} # user can request 32k or 164k, but defaults to the lower resolution


while getopts "s:f:c:n:l:o:m:p:d:a:v:" opt; do
	case $opt in 
		(s) subject_id=$OPTARG;;
		(f) freesurfer_dir=$OPTARG;;
		(c) freesurfer_sif=$OPTARG;;
		(n) neuromaps_sif=$OPTARG;;
		(l) freesurfer_license=$OPTARG;;
		(o) output_dir=$OPTARG;;
		(m) metrics=$OPTARG;;
		(p) parcellations=$OPTARG;;
		(d) native_parcellations=$OPTARG;;
		(a) anatomical_stats=$OPTARG;;
		(v) vertices=$OPTARG;;
		 *) usage;;
	esac

	case $OPTARG in
		-) echo "Command line argument $opt needs a valid argument"
		exit 1 ;;
	esac
done

if [[ "$subject_id $freesurfer_dir $freesurfer_sif $neuromaps_sif $freesurfer_license $output_dir" =~ false ]] ; then
	echo " "
	echo "$0 call is missing a required command line argument, one of: -s -f -c -n -l -o. See usage"
	echo " "
	echo " "
	echo " "
	usage
	exit 1
fi

if [[ $anatomical_stats != "true" ]] && [[ $anatomical_stats != "false" ]] ; then
	echo " "
	echo "-a must be set to true or false. See usage"
	echo " "
	echo " "
	echo " "
	usage
	exit 1
fi

if [[ $anatomical_stats == "false" ]] && [[ $metrics == "none" ]] ; then
	echo " "
	echo "anatomical stats not requested and no user-defined metrics supplied, nothing to do. See usage"
	echo " "
	echo " "
	usage
	exit 1
fi

#set -e -u -x

# Get input for this run
fs_root=$freesurfer_dir

if [[ ${subject_id} == *"long"* ]]; then
	longitudinal_fs=TRUE # running on longitudinal freesurfer output
	cross_sectional_id=$(echo ${subject_id} | cut -f 1 -d'.') #extract the cross-sectional freesurfer id from $cross.long.$base
	base_id=$(echo ${subject_id} | cut -f 3 -d'.') #extract the base template freesurfer id from $cross.long.$base
fi

if [[ ${metrics} == *"lgi"* ]]; then
	compute_lgi=TRUE # computing lgi
fi

# Set up FreeSurfer environment 
export SUBJECTS_DIR=${fs_root}
subject_fs=${SUBJECTS_DIR}/${subject_id}

# Scripts and data dirs from freesurfer_tabulate repo
SCRIPT_DIR=$(dirname "$script_name")
SCRIPT_DIR=${SCRIPTDIR:-$(realpath $SCRIPT_DIR)} #expand full path of script dir so we can bind full (instead of relative) path to the container
annots_dir=${SCRIPT_DIR}/annots
parcstats_to_tsv_script=${SCRIPT_DIR}/compile_freesurfer_parcellation_stats.py
to_cifti_script=${SCRIPT_DIR}/vertex_measures_to_cifti.py
metadata_to_bids_script=${SCRIPT_DIR}/seg_and_metadata_to_bids.py

# Set singularity params
workdir=${subject_fs}
export APPTAINERENV_OMP_NUM_THREADS=1
export APPTAINERENV_NSLOTS=1
export APPTAINERENV_ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1
export APPTAINERENV_SUBJECTS_DIR=${SUBJECTS_DIR}
export APPTAINER_TMPDIR=${SINGULARITY_TMPDIR}
export APPTAINERENV_NEUROMAPS_DATA=${SUBJECTS_DIR}/${subject_id}/trash # we're using the subject's trash directory as a temp dir for neuromaps data
singularity_cmd="singularity exec --containall --writable-tmpfs -B ${SUBJECTS_DIR} -B ${annots_dir} -B ${freesurfer_license}:/opt/freesurfer/license.txt ${freesurfer_sif}"
neuromaps_singularity_cmd="singularity exec --containall --writable-tmpfs -B ${SUBJECTS_DIR} -B ${SCRIPT_DIR} ${neuromaps_sif}"

# Special atlases that we need to warp from fsaverage to native
if [[ $parcellations == "none" ]]; then
	parcellations= 
fi
parcs=${parcellations//,/ }
# Atlases that come from freesurfer and are already in fsnative
if [[ $native_parcellations == "none" ]]; then
	native_parcellations= 
fi
native_parcs=${native_parcellations//,/ }

# Perform the mapping from fsaverage to native
for hemi in lh rh; do
    for parc in ${parcs}; do
            annot_name=${hemi}.${parc}.annot
            fsaverage_annot=${annots_dir}/${annot_name}
            native_annot=${subject_fs}/label/${annot_name}

            ${singularity_cmd} \
                mri_surf2surf \
                --srcsubject fsaverage \
                --trgsubject ${subject_id} \
                --hemi ${hemi} \
                --sval-annot ${fsaverage_annot} \
                --tval ${native_annot}
    done
done

# Run qcache on this person to get the mgh files, if it has not already been run
qcache_status=$(cat ${subject_fs}/scripts/recon-all.log | grep "Qdec Cache")
if [[ -z "$qcache_status" ]] ; then #if qcache has not been run (status is empty)
	if [[ $longitudinal_fs == TRUE ]]; then
		${singularity_cmd} recon-all -long ${cross_sectional_id} ${base_id} -qcache
	else
		${singularity_cmd} recon-all -s ${subject_id} -qcache
	fi
fi

# Create the .stats files for each annot file
for hemi in lh rh; do
    for parc in ${native_parcs} ${parcs}; do

            annot_name=${hemi}.${parc}.annot
            native_annot=${subject_fs}/label/${annot_name}
            stats_file=${subject_fs}/stats/${annot_name/.annot/.stats}

            # Freesurfer default anatomical stats
	    ${singularity_cmd} \
                mris_anatomical_stats \
                -a ${native_annot} \
                -f ${stats_file} \
                -th3 \
                -noglobal \
                ${subject_id} \
                ${hemi}
	    
	    # User-specified metric stats
	    if [[ $metrics != "none" ]]; then
		user_measures=${metrics//,/ }
		user_measures=${user_measures//"pial_lgi"/ } #remove pial_lgi from this list, handle it as a special case below
		for measure in $user_measures; do

			# Create a hemisphere-specific cortical mask to use with mri_segstats
			${singularity_cmd} \
				mri_binarize \
				--i ${subject_fs}/surf/${hemi}.${measure}.mgh \
				--min 0.01 \
				--binval 1 \
				--binvalnot 0 \
				--o ${subject_fs}/surf/${hemi}.cortexmask.mgh

			# Calculate regional measures for parcellations of interest 
			${singularity_cmd} \
				mri_segstats \
				--robust 2 \
				--in ${subject_fs}/surf/${hemi}.${measure}.mgh \
				--annot ${subject_id} ${hemi} ${parc} \
				--sum ${subject_fs}/stats/${hemi}.${parc}.${measure}.stats \
				--snr \
				--mask ${subject_fs}/surf/${hemi}.cortexmask.mgh \
				--maskthresh 0.01
		done
	    fi
	
	    # LGI
	    if [[ ${compute_lgi} == TRUE ]] && [[ $HAS_LGI -gt 0 ]]; then
                ${singularity_cmd} \
                    mri_segstats \
		    --robust 1 \
                    --annot ${subject_id} ${hemi} ${parc} \
                    --in ${subject_fs}/surf/${hemi}.pial_lgi \
                    --sum ${subject_fs}/stats/${hemi}.${parc}.pial_lgi.stats
            fi
    done
done

# Create the tsvs for the regional stats from the parcellations
export APPTAINERENV_anatomical_stats=${anatomical_stats} #export anatomical stats flag as singularity environment variable to be accessible to parcstats_to_tsv_script
if [[ $metrics != "none" ]]; then #export user-defined metrics as a singularity environment variable to be accessible in parcstats_to_tsv_script
	export APPTAINERENV_user_measures=${user_measures}
fi
if [[ ${compute_lgi} == TRUE ]]; then #indicate whether LGI calculation was attempted as a singularity environment variable 
	export APPTAINERENV_LGI=${compute_lgi}
fi	
${neuromaps_singularity_cmd} \
python ${parcstats_to_tsv_script} ${subject_id} ${native_parcs} ${parcs} #parcellation stats tsv
${neuromaps_singularity_cmd} \
python ${metadata_to_bids_script} ${subject_id} #metadata

# Get these into MGH
if [[ ${compute_lgi} == TRUE ]] && [[ $HAS_LGI -gt 0 ]]; then
	if [[ $longitudinal_fs == TRUE ]]; then
		${singularity_cmd} recon-all -long ${cross_sectional_id} ${base_id} -qcache -measure pial_lgi
	else
		${singularity_cmd} recon-all -s ${subject_id} -qcache -measure pial_lgi
	fi
fi	

# Big picture here: get these MGH formatted metrics into cifti format
# first we have to export them from mgh to gifti. We'll use freesurfer for this
# but it will create malformed gifti files :S
cd ${subject_fs}/surf

if [[ $anatomical_stats == "true" ]] ; then
	for hemi in lh rh; do
    		for mgh_surf in ${hemi}*area*fsaverage.mgh ${hemi}*curv*fsaverage.mgh ${hemi}*sulc*fsaverage.mgh ${hemi}*thickness*fsaverage.mgh ${hemi}*volume*fsaverage.mgh; do
	    		if [[ $mgh_surf != *"fwhm"* ]]; then #not resampling all smoothed data to cifti. smooth output with -cifti-smoothing
        			${singularity_cmd} mris_convert \
            			-c ${PWD}/${mgh_surf} \
            			${SUBJECTS_DIR}/fsaverage/surf/${hemi}.white \
            			${PWD}/${mgh_surf/%.mgh/.malformed.shape.gii}
	    		fi
		done
	done
fi

if [[ $metrics != "none" ]]; then
	user_measures=${metrics//,/ }
	user_measures=${user_measures//"pial_lgi"/ } #remove pial_lgi from this list, handle it as a special case below
	for hemi in lh rh; do
		for measure in $user_measures; do
			for mgh_surf in ${hemi}*${measure}*fsaverage.mgh; do
	    			if [[ $mgh_surf != *"fwhm"* ]]; then #not resampling all smoothed data to cifti. smooth output with -cifti-smoothing
					${singularity_cmd} mris_convert \
            				-c ${PWD}/${mgh_surf} \
					${SUBJECTS_DIR}/fsaverage/surf/${hemi}.white \
            				${PWD}/${mgh_surf/%.mgh/.malformed.shape.gii}
				fi
			done
		done
	done
fi

# Finally, use neuromaps to go from fsaverage to fsLR
export APPTAINERENV_vertices=${vertices} #export requested cifti vertex density as singularity environment variable to be accessible to to_cifti_script
${neuromaps_singularity_cmd} \
  python ${to_cifti_script} \
  ${subject_fs}

# Remove the malformed data from surf/
rm -fv ${subject_fs}/surf/*malformed*

# gather fsaverage mgh files
mkdir -p "${output_dir}/${subject_id}_fsaverage"
if [[ $anatomical_stats == "true" ]] ; then
	cp ${subject_fs}/surf/*area*fsaverage.mgh "${output_dir}/${subject_id}_fsaverage/"
	cp ${subject_fs}/surf/*curv*fsaverage.mgh "${output_dir}/${subject_id}_fsaverage/"
	cp ${subject_fs}/surf/*sulc*fsaverage.mgh "${output_dir}/${subject_id}_fsaverage/"
	cp ${subject_fs}/surf/*thickness*fsaverage.mgh "${output_dir}/${subject_id}_fsaverage/"
	cp ${subject_fs}/surf/*volume*fsaverage.mgh "${output_dir}/${subject_id}_fsaverage/"
fi
if [[ $metrics != "none" ]]; then
	user_measures=${metrics//,/ }
	for metric in $user_measures; do
		cp ${subject_fs}/surf/*$metric*fsaverage.mgh "${output_dir}/${subject_id}_fsaverage/"
	done
fi
rm ${output_dir}/${subject_id}_fsaverage/*fwhm* #not saving smoothed surface metrics to the fsaverage tar ball

# gather the fslr cifti files
mkdir -p "${output_dir}/${subject_id}_fsLR_den-$vertices"
mv ${subject_fs}/surf/*.nii "${output_dir}/${subject_id}_fsLR_den-$vertices/"

# Move the surface stats tsv
mv ${subject_fs}/stats/*regionsurfacestats.tsv ${output_dir}/

# Move the whole brain data and corresponding metadata
mv ${subject_fs}/stats/*brainmeasures.* ${output_dir}/

# Remove temp files from neuromaps
rm -rf ${subject_fs}/trash/*

cd ${output_dir}
tar cvfJ ${subject_id}_fsaverage.tar.xz ${subject_id}_fsaverage
tar cvfJ ${subject_id}_fsLR_den-$vertices.tar.xz ${subject_id}_fsLR_den-$vertices
rm -rf ${subject_id}_fsaverage ${subject_id}_fsLR_den-$vertices

