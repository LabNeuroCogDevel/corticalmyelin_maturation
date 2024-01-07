#!/bin/bash

#A script to create dense and parcellated LH gene expression maps for genes of interest, using the data from Wagstyl et al., 2024 and the Multiscale Atlas of Gene Expression for Integrative Cortical Cartography (MAGICC) 

script_name=$0
SCRIPT_DIR=$(dirname "$script_name")
SCRIPT_DIR=$(realpath $SCRIPT_DIR)
OUTPUT_DIR=/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA_magicc/expression_maps
wb_command=/Volumes/Hera/Projects/corticalmyelin_development/software/workbench/bin_linux64/wb_command

for gene in MBP OLIG1 OLIG2 MAG MOG SLC17A6; do
	#create dense gene expression lh gifti
	python $SCRIPT_DIR/create_AHBAmagicc_genemap.py $gene $OUTPUT_DIR
	#create dense gene expression cifti (with lh data only)
	wb_command -cifti-create-dense-scalar -left-metric $OUTPUT_DIR/source-magicc_desc-${gene}expression_space-fsLR_den-32k.func.gii $OUTPUT_DIR/source-magicc_desc-${gene}expression_space-fsLR_den-32k.dscalar.nii
	#parcellate the dense expression map 
	wb_command -cifti-parcellate $OUTPUT_DIR/source-magicc_desc-${gene}expression_space-fsLR_den-32k.dscalar.nii /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas.dlabel.nii COLUMN $OUTPUT_DIR/source-magicc_desc-${gene}expression_space-fsLR_den-32k.pscalar.nii -legacy-mode 
done

