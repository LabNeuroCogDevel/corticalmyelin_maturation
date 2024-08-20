#A script to test for age*depth interactions in R1 developmental profiles
library(tidyr)
library(mgcv)
library(gratia)
library(tidyverse)
library(dplyr)

############################################################################################################
#### Prepare Data and Functions ####

#Brain region list
glasser.regions <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist.csv")

#Depth-specific R1 measures for final study sample
myelin.glasser.7T <- readRDS("/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/depthR1_glasseratlas_finalsample.RDS")

for(depth in 1:7){
  myelin.glasser.7T[[depth]]$subject_id <- as.factor(myelin.glasser.7T[[depth]]$subject_id) #format as factor
  myelin.glasser.7T[[depth]]$depth <- depth #add depth number to df
}

myelin.glasser.7T.alldepths <- bind_rows(myelin.glasser.7T)
names(myelin.glasser.7T.alldepths) <- gsub("-", "_", names(myelin.glasser.7T.alldepths))


#Gam functions
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/gam_models/gam_functions.R")

############################################################################################################
#### Fit age by depth interaction GAMs for every cortical region ####

#Run the gam.tensorproduct.interaction function for every region
gam.outputs.regionlist <- lapply(glasser.regions$orig_parcelname, function(r){  #list of gam results, list elements are regions
                      gam.tensorproduct.interaction(input.df = myelin.glasser.7T.alldepths, region = as.character(r), 
                                      smooth_var = "age", smooth_var_knots = 3, smooth_int_var = "depth", smooth_int_var_knots = 5, 
                                      linear_covariates = "NA", id_var = "subject_id", random_intercepts = TRUE, random_slopes = FALSE, set_fx = FALSE)}) 

#Combine regional results into a single df
gam.agebydepth.interaction.statistics <- bind_rows(gam.outputs.regionlist)
saveRDS(gam.agebydepth.interaction.statistics, "/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/developmental_effects/agebydepth_interaction_gamstatistics.RDS")
