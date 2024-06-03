# A script to calculate regional R1 signal-to-noise ratio and identify low SNR parcels for exclusion
library(dplyr)
library(tidyverse)
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/surface_metrics/surface_measures/extract_surfacestats.R")

############################################################################################################
#### Extract Depth-Dependent Regional R1 Signal-to-Noise Ratio ####

# SNR measures
R1.SNR.measures <- list("SNR_R1map.0.8%","SNR_R1map.0.7%","SNR_R1map.0.6%","SNR_R1map.0.5%","SNR_R1map.0.4%","SNR_R1map.0.3%","SNR_R1map.0.2%") #measures to extract data for 

SNR.glasser.7T <- lapply(R1.SNR.measures, function(x) {
  extract_surfacestats("glasser", x)}) 

SNR.glasser.7T <- do.call(rbind, SNR.glasser.7T)

############################################################################################################
#### Calculate Average Regional R1 SNR ####

regionalSNR <- SNR.glasser.7T %>% select(contains("ROI")) %>% colMeans() %>% as.data.frame() %>% set_names("R1.SNR")
regionalSNR$orig_parcelname <- row.names(regionalSNR)
regionalSNR <- regionalSNR %>% filter(R1.SNR < 20) #lower SNR parcels

############################################################################################################
#### Exclude Low SNR Regions in Frontal and Temporal Poles ####

poles.SNR <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/SNR/glasser_poles_SNR.csv")
SNR.exclusion <- regionalSNR[regionalSNR$orig_parcelname %in% poles.SNR$orig_parcelname,]

write.csv(SNR.exclusion, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/SNR/glasser_SNR_exclusion.csv", quote = F, row.names = F)