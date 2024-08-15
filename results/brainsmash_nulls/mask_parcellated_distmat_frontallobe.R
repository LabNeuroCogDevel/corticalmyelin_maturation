#A script to mask left and right hemisphere glasser parcel distance matrices and retain just the frontal lobe
library(dplyr)
library(readr)
library(cifti)

# Glasser atlas frontal regions
glasser.regions <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist.csv") 
glasser.frontal <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist_frontallobe.csv")

# Left and right hemisphere glasser atlas distance matrices
###All regions
lh.distmat.all <- read_table("/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/LeftParcellatedGeodesicDistmat_fslr32k_glasser.txt", col_names = F) #dist mat with all regions
rh.distmat.all <- read_table("/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/RightParcellatedGeodesicDistmat_fslr32k_glasser.txt", col_names = F)

###Frontal lobe distance matrices
colnames(lh.distmat.all) <- glasser.regions$orig_parcelname[181:360]
lh.distmat.all$orig_parcelname <- glasser.regions$orig_parcelname[181:360]
lh.distmat.frontal <- lh.distmat.all[lh.distmat.all$orig_parcelname %in% glasser.frontal$orig_parcelname,]
lh.distmat.regions <- lh.distmat.frontal$orig_parcelname
lh.distmat.frontal <- lh.distmat.frontal %>% select(matches(lh.distmat.regions))
identical(lh.distmat.regions, names(lh.distmat.frontal))
write.table(lh.distmat.frontal, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/LeftParcellatedGeodesicDistmat_fslr32k_glasser_frontallobe.txt", row.names = F, quote = F, col.names = F)
write.table(lh.distmat.regions, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/LeftDistmat_frontallobe_regionorder.txt", row.names = F, quote = F, col.names = F)

colnames(rh.distmat.all) <- glasser.regions$orig_parcelname[1:180]
rh.distmat.all$orig_parcelname <- glasser.regions$orig_parcelname[1:180]
rh.distmat.frontal <- rh.distmat.all[rh.distmat.all$orig_parcelname %in% glasser.frontal$orig_parcelname,]
rh.distmat.regions <- rh.distmat.frontal$orig_parcelname
rh.distmat.frontal <- rh.distmat.frontal %>% select(matches(rh.distmat.regions))
identical(rh.distmat.regions, names(rh.distmat.frontal))
write.table(rh.distmat.frontal, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/RightParcellatedGeodesicDistmat_fslr32k_glasser_frontallobe.txt", row.names = F, quote = F, col.names = F)
write.table(rh.distmat.regions, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/RightDistmat_frontallobe_regionorder.txt", row.names = F, quote = F, col.names = F)

# S-A axis frontal lobe rankings (in distance matrix order)
SAaxis.cifti <- read_cifti("/Volumes/Hera/Projects/corticalmyelin_development/Maps/S-A_ArchetypalAxis/FSLRVertex/SensorimotorAssociation_Axis_parcellated/SensorimotorAssociation.Axis.Glasser360.pscalar.nii")
SAaxis <- data.frame(SA.axis = rank(SAaxis.cifti$data), orig_parcelname = names(SAaxis.cifti$Parcel))

SAaxis.lh.frontal <- SAaxis[SAaxis$orig_parcelname %in% lh.distmat.regions,]
identical(SAaxis.lh.frontal$orig_parcelname, lh.distmat.regions)
SAaxis.lh.frontal <- SAaxis.lh.frontal %>% select(SA.axis)
write.table(SAaxis.lh.frontal, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/smash_data/SA.lh.frontallobe.glasser.txt", row.names = F, quote = F, col.names = F)

SAaxis.rh.frontal <- SAaxis[SAaxis$orig_parcelname %in% rh.distmat.regions,]
identical(SAaxis.rh.frontal$orig_parcelname, rh.distmat.regions)
SAaxis.rh.frontal <- SAaxis.rh.frontal %>% select(SA.axis)
write.table(SAaxis.rh.frontal, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/smash_data/SA.rh.frontallobe.glasser.txt", row.names = F, quote = F, col.names = F)

# Cytoarchitectural variation in frontal lobe (in distance matrix order)
bigbrain.cifti <- read_cifti("/Volumes/Hera/Projects/corticalmyelin_development/Maps/BigBrain_histologygradient/BigBrain.Histology.pscalar.nii")
bigbrain <- data.frame(cytoarchitecture.gradient = bigbrain.cifti$data, orig_parcelname = names(bigbrain.cifti$Parcel))

bigbrain.lh.frontal <- bigbrain[bigbrain$orig_parcelname %in% lh.distmat.regions,]
identical(bigbrain.lh.frontal$orig_parcelname, lh.distmat.regions)
bigbrain.lh.frontal <- bigbrain.lh.frontal %>% select(cytoarchitecture.gradient)
write.table(bigbrain.lh.frontal, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/smash_data/Bigbrain.lh.frontallobe.glasser.txt", row.names = F, quote = F, col.names = F)

bigbrain.rh.frontal <- bigbrain[bigbrain$orig_parcelname %in% rh.distmat.regions,]
identical(bigbrain.rh.frontal$orig_parcelname, rh.distmat.regions)
bigbrain.rh.frontal <- bigbrain.rh.frontal %>% select(cytoarchitecture.gradient)
write.table(bigbrain.rh.frontal, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/Brainsmash/smash_data/Bigbrain.rh.frontallobe.glasser.txt", row.names = F, quote = F, col.names = F)

