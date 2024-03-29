#!/bin/bash

#A script to create cifti/gifti/annot EEG electrode atlases with valid label tables or color LUTs. The goal of creating fsaverage annots with EEG electrode locations is to use them as an atlas for cortical myelin extraction

script_name=$0
SCRIPT_DIR=$(dirname "$script_name")
SCRIPT_DIR=${SCRIPTDIR:-$(realpath $SCRIPT_DIR)}
EEGatlas_dir=/Volumes/Hera/Projects/corticalmyelin_development/Maps/EEG_electrode_atlas #directory with EEG electrode surface coordinates in MNI space and EEG labeltable
annots_dir=/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/surface_metrics/fstabulate/annots #study parcellation annot directory, where final output will go
wb_command=/Volumes/Hera/Projects/corticalmyelin_development/software/workbench/bin_linux64/wb_command

## Create MNI-space spherical ROIs from EEG coordinates
mlr --tsv --icsv  cut -f x,y,z < $EEGatlas_dir/electrodeMNIcoordinatesCortex_20240202.csv | awk '(NR>1 && NF==3){print $0 "\t" NR-1}' | 3dUndump -prefix $EEGatlas_dir/electrodeLocs_MNIcoordinates_cortex_atlas.nii.gz -master /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz -srad 7 -xyz -overwrite -

## Create EEG atlas giftis by transforming volumetric labels to the fsaverage surface
python $SCRIPT_DIR/EEGatlas_fsaverage_giftis.py

## Merge EEG atlas fsaverage giftis into a cifti
wb_command -cifti-create-dense-scalar -left-metric $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-L.shape.gii -right-metric $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-R.shape.gii $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k.dscalar.nii 

## Turn the metric data into a valid cifti label file
wb_command -cifti-label-import $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k.dscalar.nii $EEGatlas_dir/EEGatlas_labeltable.txt $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k.dlabel.nii -discard-others -unlabeled-value 0 

## Dilate the cifti labels
wb_command -cifti-dilate $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k.dlabel.nii COLUMN 4 0 $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k.dlabel.nii -left-surface /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-L_den-164k_midthickness.surf.gii -right-surface /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-R_den-164k_midthickness.surf.gii -nearest #nearest neighborhood ROI dilation using surface geometry

## Turn the cifti dlabel into two gifti labels
wb_command -cifti-separate $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k.dlabel.nii COLUMN -label CORTEX_LEFT $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-L.label.gii -label CORTEX_RIGHT $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-R.label.gii

## Convert the gifti label files to .annots in the fstabule directory
#### Each label name *must* have a different color code to work with freesurfer, even if label numbers are different (and compatable with workbench)
mris_convert --annot $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-L.label.gii /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-L_den-164k_white.surf.gii $annots_dir/lh.EEGatlas.annot
mris_convert --annot $EEGatlas_dir/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-R.label.gii /Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsaverage/tpl-fsaverage_hemi-R_den-164k_white.surf.gii $annots_dir/rh.EEGatlas.annot
