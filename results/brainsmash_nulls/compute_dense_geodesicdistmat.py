#A script to construct a geodesic distance matrix for left and right cortical surfaces

from brainsmash.workbench.geo import cortex
lh_surf = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsLR/tpl-fsLR_den-32k_hemi-L_midthickness.surf.gii"
cortex(surface = lh_surf, outfile = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/LeftDenseGeodesicDistmat_fslr32k.txt", euclid = False)

rh_surf = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/tpl-fsLR/tpl-fsLR_den-32k_hemi-R_midthickness.surf.gii"
cortex(surface = rh_surf, outfile = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/RightDenseGeodesicDistmat_fslr32k.txt", euclid = False)
