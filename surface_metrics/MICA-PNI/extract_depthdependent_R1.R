#A script to get R1 intensity values in the cortical ribbon from the MICA-PNI dataset 
library(dplyr)
library(gifti)

############################################################################################################
glasser.regions <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist.csv")
glasser.snr.exclude <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/SNR/glasser_SNR_exclusion.csv")
glasser.frontal <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist_frontallobe.csv")

#### Read in MICA-PNI T1 intensity profiles and convert to R1 intensity (1/T1) ####
# MP2RAGE-derived T1 data is 0.5 mm resolution
# T1 intensities were sampled by constructing 16 equivolumetric surfaces and removing boundary surfaces for partial voluming, resulting in 14 T1 values in the cortical ribbon

MICA.subjects <- sprintf("sub-PNC%03d", 1:10)

MICA.R1.intensities <- list()

for (sub in MICA.subjects){
  #read in
  filepath = sprintf("/Volumes/Hera/Projects/corticalmyelin_development/MICA-PNI/%s/ses-01/mpc/acq-T1map/%s_ses-01_atlas-glasser-360_desc-intensity_profiles.shape.gii", sub, sub)
  intensity.gifti <- read_gifti(filepath)
  
  #add colnames
  intensity.profile <- intensity.gifti$data$shape %>% as.data.frame() %>% select(-V1, -V182) #remove empty labels. df is 14 intensities x 360 regions
  colnames(intensity.profile)[1:180] <- glasser.regions$label[181:360] #micapipe concatenates hemsipheres as L --> R
  colnames(intensity.profile)[181:360] <- glasser.regions$label[1:180]
  
  #convert to R1 in s-1 (1/T1)
  intensity.profile.R1 <- (1/intensity.profile)*1000
  
  intensity.profile.R1$depth <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14) #add depth column. 1 is superficial, 14 is deep
  intensity.profile.R1$subject_id <- sub #add subject identifier
  MICA.R1.intensities[[sub]] <- intensity.profile.R1
}

saveRDS(MICA.R1.intensities, file = "/Volumes/Hera/Projects/corticalmyelin_development/MICA-PNI/depthR1_glasseratlas_MICAPNI.RDS")
