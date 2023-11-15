#!/bin/bash

# Use CuBIDS to look at metadata and acquisition heterogeneity 

## Install CuBIDS
conda activate cubids
pip install CuBIDS
conda install nodejs
npm install -g bids-validator@1.7.2

bids_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
cubids-print-metadata-fields $bids_dir #ensure metadata of interest is in jsons
cubids-group $bids_dir $bids_dir/CuBIDS/v0 #create spreadshseets with metadata information and key param groups 
cubids-add-nifti-info $bids_dir
cubids-group $bids_dir $bids_dir/CuBIDS/v1 #create spreadshseets with metadata information and key param groups after running cubids-add-nifti-info 

