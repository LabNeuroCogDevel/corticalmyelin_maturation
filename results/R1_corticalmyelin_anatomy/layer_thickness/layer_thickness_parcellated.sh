#!/bin/bash

# A script to parcellate BigBrain layer thickness maps

wb_command=/Volumes/Hera/Projects/corticalmyelin_development/software/workbench/bin_linux64/wb_command
atlasdir=/Volumes/Hera/Projects/corticalmyelin_development/software/workbench/standard_mesh_atlases/resample_fsaverage
layerdir=/Volumes/Hera/Projects/corticalmyelin_development/Maps/BigBrain_layerthickness/BBW_BigData

for layer in layer1 layer2 layer3 layer4 layer5 layer6; do
	for hemi in L R; do

	#transform data from fsaverage to fslr surface
		wb_command -metric-resample ${layerdir}/tpl-fsaverage_hemi-${hemi}_den-164k_desc-${layer}.shape.gii ${atlasdir}/fsaverage_std_sphere.${hemi}.164k_fsavg_${hemi}.surf.gii ${atlasdir}/fs_LR-deformed_to-fsaverage.${hemi}.sphere.32k_fs_LR.surf.gii ADAP_BARY_AREA ${layerdir}/tpl-fs_LR_hemi-${hemi}_den-32k_desc-${layer}.shape.gii -area-metrics ${atlasdir}/fsaverage.${hemi}.midthickness_va_avg.164k_fsavg_${hemi}.shape.gii ${atlasdir}/fs_LR.${hemi}.midthickness_va_avg.32k_fs_LR.shape.gii
	done

	#combine left and right hemisphere data into a cifti
	wb_command -cifti-create-dense-scalar -left-metric ${layerdir}/tpl-fs_LR_hemi-L_den-32k_desc-${layer}.shape.gii -right-metric ${layerdir}/tpl-fs_LR_hemi-R_den-32k_desc-${layer}.shape.gii ${layerdir}/source-bigbrain_desc-${layer}thickness_space-fsLR_den-32k.dscalar.nii

	#parcellate with the HCP-MMP atlas
	wb_command -cifti-parcellate ${layerdir}/source-bigbrain_desc-${layer}thickness_space-fsLR_den-32k.dscalar.nii /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas.dlabel.nii COLUMN ${layerdir}/source-bigbrain_desc-${layer}thickness_space-fsLR_den-32k.pscalar.nii 
done
