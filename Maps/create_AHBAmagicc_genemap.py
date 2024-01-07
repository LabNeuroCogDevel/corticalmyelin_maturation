import sys
import subprocess
import os
import nibabel as nib
import pandas as pd
import numpy as np

#Read in MAGICC gene expression and gene info data
gene_expression = np.load('/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA_magicc/magicc_expression_data/ahba_vertex.npy') #20,781 genes by 32492 vertices
gene_info = pd.read_csv('/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA_magicc/magicc_expression_data/SuppTable2.csv', low_memory=False) #gene names and indices, along with gene characteristics

#Read in relevant gifti files and create a cortex mask
surf = nib.load('/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA_magicc/magicc_expression_data/fs_LR.32k.L.inflated.surf.gii') 
parcellation = nib.load('/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA_magicc/magicc_expression_data/Glasser_2016.32k.L.label.gii')
cortex_mask = parcellation.darrays[0].data>0 #cortex versus medial wall mask

#Get across-donor normalized gene expression for user-input gene of interest 
mygene_name = sys.argv[1]
mygene_index = np.where(gene_info['gene.symbol']==mygene_name)[0][0]
mygene_expression = gene_expression[mygene_index]
mygene_expression_masked = mygene_expression*cortex_mask
mygene_expression_masked = mygene_expression_masked.astype(np.float32)

#Create lh gifti image and save 
data_lh = nib.gifti.gifti.GiftiImage()
data_lh.add_gifti_data_array(nib.gifti.gifti.GiftiDataArray(data = mygene_expression_masked))
data_lh.meta['AnatomicalStructurePrimary'] = 'CortexLeft'
outputpath = sys.argv[2]
fname_lh = 'source-magicc_desc-{0}expression_space-fsLR_den-32k.func.gii'.format(mygene_name)
nib.save(data_lh, outputpath + "/" + fname_lh)
