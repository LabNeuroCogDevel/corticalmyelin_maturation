#!/bin/bash

#A script to create cifti/gifti/annot MRSI atlases with valid label tables or color LUTs. The goal of creating fsaverage annots with MRSI regions is to use them as an atlas for cortical myelin extraction

script_name=$0
SCRIPT_DIR=$(dirname "$script_name")
SCRIPT_DIR=${SCRIPTDIR:-$(realpath $SCRIPT_DIR)}
MRSIatlas_dir=/Volumes/Hera/Projects/corticalmyelin_development/Maps/MRSI_region_atlas #directory with MRSI region MNI coordinates where intermediate niftis, giftis, and ciftis will go
annots_dir=/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/surface_metrics/fstabulate/annots #study parcellation annot directory, where final output will go
wb_command=/Volumes/Hera/Projects/corticalmyelin_development/software/workbench/bin_linux64/wb_command

## Create MNI-space spherical ROIs for MRSI regions based on manually-selected representative coordinates. Coordinate placement was validated as representative by comparing generated ROIs to a voxel count heatmap derived from each subject's ROIs in MNI space (ROIs cover areas of highest counts)
mlr --tsv --icsv  cut -f x,y,z < $MRSIatlas_dir/MNI152_2009cAsym_2mm_coordinates_13MP20200207.csv | awk '(NR>1 && NF==3){print $0 "\t" NR-1}' | 3dUndump -prefix $MRSIatlas_dir/MRSIatlas_MNI152space_13MP20200207.nii.gz -master /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-02_T1w.nii.gz -srad 6 -orient RAI -xyz -overwrite -

## Create MRSI atlas giftis by transforming volumetric labels to the fsaverage surface
python $SCRIPT_DIR/MRSIatlas_fsaverage_giftis.py

## Merge MRSI atlas fsaverage giftis into a cifti
wb_command -cifti-create-dense-scalar -left-metric $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-L.shape.gii -right-metric $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-R.shape.gii $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k.dscalar.nii

## Turn the metric data into a valid cifti label file
wb_command -cifti-label-import $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k.dscalar.nii $MRSIatlas_dir/MRSIatlas_labeltable.txt $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k.dlabel.nii -discard-others -unlabeled-value 0 -drop-unused-labels #discard others sets any values not mentioned in the label list to unlabeled (0) 

## Dilate the cifti labels
wb_command -cifti-dilate $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k.dlabel.nii COLUMN 6 0 $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k.dlabel.nii -left-surface /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-L_den-164k_midthickness.surf.gii -right-surface /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-R_den-164k_midthickness.surf.gii -nearest #nearest neighborhood ROI dilation using surface geometry

## Turn the cifti dlabel into two gifti labels
wb_command -cifti-separate $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k.dlabel.nii COLUMN -label CORTEX_LEFT $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-L.label.gii -label CORTEX_RIGHT $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-R.label.gii

## Convert the gifti label files to .annots in the fstabule directory
#### Each label name *must* have a different color code to work with freesurfer, even if label numbers are different (and compatable with workbench)
mris_convert --annot $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-L.label.gii /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-L_den-164k_white.surf.gii $annots_dir/lh.MRSIatlas.annot
#/opt/ni_tools/freesurfer7.4.1/subjects/fsaverage/surf/lh.white $annots_dir/lh.MRSIatlas.annot
mris_convert --annot $MRSIatlas_dir/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-R.label.gii /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-R_den-164k_white.surf.gii $annots_dir/rh.MRSIatlas.annot 
#/opt/ni_tools/freesurfer7.4.1/subjects/fsaverage/surf/rh.white $annots_dir/rh.MRSIatlas.annot
