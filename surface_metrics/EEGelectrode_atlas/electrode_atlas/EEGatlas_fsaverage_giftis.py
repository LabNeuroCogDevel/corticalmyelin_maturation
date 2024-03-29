#A script to take the MNI-space EEG cortical surface coordinate atlas and map it to the fsaverage cortical surface

import nibabel as nib
import pandas as pd
from neuromaps import transforms

#Read in the MNI-space EEG atlas and map it to the fsaverage surface
EEG_volume = nib.load("/Volumes/Hera/Projects/corticalmyelin_development/Maps/EEG_electrode_atlas/electrodeLocs_MNIcoordinates_cortex_atlas.nii.gz") #atlas in MNI152NLin2009cAsym
EEGatlas_fsaverage = transforms.mni152_to_fsaverage(EEG_volume, '164k', method='nearest') #mni to fsaverage

#Get left and right hemisphere EEG atlas giftis
EEG_fsaverage_lh, EEG_fsaverage_rh = EEGatlas_fsaverage #left and right hemisphere giftis, tuple is L->R ordered
EEG_fsaverage_lh.meta['AnatomicalStructurePrimary'] = 'CortexLeft'
EEG_fsaverage_rh.meta['AnatomicalStructurePrimary'] = 'CortexRight'

#Save out giftis
nib.save(EEG_fsaverage_lh, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/EEG_electrode_atlas/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-L.shape.gii") 
nib.save(EEG_fsaverage_rh, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/EEG_electrode_atlas/source-64electrodeMNI_desc-EEGatlas_space-fsaverage_den-164k_hemi-R.shape.gii") 
