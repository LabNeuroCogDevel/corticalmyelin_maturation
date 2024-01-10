import nibabel as nib
import pandas as pd
from neuromaps import transforms

MWF = nib.load("/Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019/Atlas_Mean.nii.gz") #load in MNI space myelin water fraction map
MWF_fsavg = transforms.mni152_to_fsaverage(MWF, '164k') #project the map to the fsaverage surface
MWF_fsavg_lh, MWF_fsavg_rh = MWF_fsavg #access left and right hemisphere giftis
MWF_fsavg_lh.meta['AnatomicalStructurePrimary'] = 'CortexLeft' #add anatomical structure lh
MWF_fsavg_rh.meta['AnatomicalStructurePrimary'] = 'CortexRight' #add anatomical structure rh
outputpath = '/Volumes/Hera/Projects/corticalmyelin_development/Maps/MyelinWaterFraction_Liu2019' #outputs go here
fname_lh = 'source-Liu2019_desc-MWFmap_space-fsaverage_den-164k_hemi-L.func.gii' #output filename lh
fname_rh = 'source-Liu2019_desc-MWFmap_space-fsaverage_den-164k_hemi-R.func.gii' #output filename rh
nib.save(MWF_fsavg_lh, outputpath + "/" + fname_lh) #save lh MWF gifti
nib.save(MWF_fsavg_rh, outputpath + "/" + fname_rh) #save rh MWF gifti

