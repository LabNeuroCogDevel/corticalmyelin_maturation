#A script to take the MNI-space MRSI cortical region atlas and map it to the fsaverage cortical surface

import nibabel as nib
import pandas as pd
from neuromaps import transforms

#Read in the MNI-space MRSI atlas and map it to the fsaverage surface
MRSI_volume = nib.load("/Volumes/Hera/Projects/corticalmyelin_development/Maps/MRSI_region_atlas/MRSIatlas_MNI152space_13MP20200207.nii.gz") #atlas in MNI152NLin2009cAsym
MRSI_fsaverage = transforms.mni152_to_fsaverage(MRSI_volume, '164k', method='nearest') #mni to fsaverage

#Get left and right hemisphere MRSI atlas giftis
MRSI_fsaverage_lh, MRSI_fsaverage_rh = MRSI_fsaverage #left and right hemisphere giftis, tuple is L->R ordered
MRSI_fsaverage_lh.meta['AnatomicalStructurePrimary'] = 'CortexLeft'
MRSI_fsaverage_rh.meta['AnatomicalStructurePrimary'] = 'CortexRight'

#Save out giftis
nib.save(MRSI_fsaverage_lh, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/MRSI_region_atlas/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-L.shape.gii")
nib.save(MRSI_fsaverage_rh, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/MRSI_region_atlas/source-13MP20200207_desc-MRSIatlas_space-fsaverage_den-164k_hemi-R.shape.gii")
