#!/bin/bash

#A script to calculate mean myelin water fraction values in HCP-MMP glasser parcels, by projecting the MNI-space myelin imaging template from Liu et al., 2019, Journal of Neuroimaging https://onlinelibrary.wiley.com/doi/10.1111/jon.12657 to the fsaverage surface and parcellating. The myelin water atlas was downloaded from https://sourceforge.net/projects/myelin-water-atlas/

script_name=$0
SCRIPT_DIR=$(dirname "$script_name")
SCRIPT_DIR=$(realpath $SCRIPT_DIR)

# Create a dlabel.nii cifti label atlas of the HCP-MMP parcellation in fsaverage space
##convert freesurfer annots to giftis
mris_convert --annot /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/lh.glasser.annot /opt/ni_tools/freesurfer7.4.1/subjects/fsaverage/surf/lh.white /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage_den-164k_desc-atlas_hemi-L.label.gii
mris_convert --annot /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/rh.glasser.annot /opt/ni_tools/freesurfer7.4.1/subjects/fsaverage/surf/rh.white /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage_den-164k_desc-atlas_hemi-R.label.gii
##merge giftis into a dlabel
wb_command=/Volumes/Hera/Projects/corticalmyelin_development/software/workbench/bin_linux64/wb_command
${wb_command} -cifti-create-label -right-label /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage_den-164k_desc-atlas_hemi-R.label.gii -left-label /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage_den-164k_desc-atlas_hemi-L.label.gii /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage_den-164k_desc-atlas.dlabel.nii
 
# Project the MWF atlas to the fsaverage surface with neuromaps and save out lh and rh giftis
python $SCRIPT_DIR/parcellate_MWFmap.py 

# Create a dscalar.nii cifti metric file on the fsaverage surface
${wb_command} -cifti-create-dense-scalar -left-metric  /Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/source-Liu2019_desc-MWFmap_space-fsaverage_den-164k_hemi-L.func.gii -right-metric /Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/source-Liu2019_desc-MWFmap_space-fsaverage_den-164k_hemi-R.func.gii /Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/source-Liu2019_desc-MWFmap_space-fsaverage_den-164k.dscalar.nii

# Parcellate the MWF atlas with the fsaverage HCP-MMP dlabel file
${wb_command} -cifti-parcellate /Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/source-Liu2019_desc-MWFmap_space-fsaverage_den-164k.dscalar.nii /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage_den-164k_desc-atlas.dlabel.nii COLUMN /Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/source-Liu2019_desc-MWFmap_space-fsaverage_den-164k_atlas-glasser360.pscalar.nii   

#3dROIstats -mask /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/tpl-MNI152NLin6Asym_atlas-Glasser_res-01_dseg.nii.gz -nobriklab -1DRformat -nomeanout -nzmean /Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/Atlas_Mean.nii.gz >> /Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/MWF_atlas_glasser360.csv 
