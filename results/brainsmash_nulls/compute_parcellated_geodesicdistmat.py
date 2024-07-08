#A script to parcellate the distance matrix created by compute_dense_geodesicdistmat.py 

from brainsmash.workbench.geo import parcellate
lh_dense_distance = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/LeftDenseGeodesicDistmat_fslr32k.txt"
rh_dense_distance = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/RightDenseGeodesicDistmat_fslr32k.txt"

lh_glasser_distance = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/LeftParcellatedGeodesicDistmat_fslr32k_glasser.txt"
rh_glasser_distance = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/RightParcellatedGeodesicDistmat_fslr32k_glasser.txt"

lh_dlabel = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas_hemi-L.dlabel.nii"
rh_dlabel = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas_hemi-R.dlabel.nii"

parcellate(lh_dense_distance, lh_dlabel, lh_glasser_distance)
parcellate(rh_dense_distance, rh_dlabel, rh_glasser_distance)
