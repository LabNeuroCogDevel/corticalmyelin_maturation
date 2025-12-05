#A script to fit GAMs to examine associations between superficial/deep R1 and the EEG aperiodic exponent using source-localized EEG
library(tidyr)
library(mgcv)
library(gratia)
library(tidyverse)
library(dplyr)
setwd("/Users/valeriesydnor/Documents/Image_Processing/corticalmyelin_development/")

###########################################################################################################
#### Prepare Data and Functions ####

#Brain region list
glasser.frontal <- read.csv("./Maps/HCPMMP_glasseratlas/glasser360_regionlist_frontallobe.csv")

#Participant list
participants <- read.csv("./sample_info/7T_MP2RAGE_finalsample_demographics.csv")

#EEG aperiodic exponent in glasser regions for final EEG sample
EEG.exponent <- readRDS("./EEG/aperiodicexponent_glasseratlas_finalsample.RDS")

#Superficial and deep R1 measures for final study sample
myelin.compartments.7T <- readRDS("./BIDS/derivatives/surface_metrics/compartmentsR1_glasseratlas_finalsample.RDS")
myelin.superficial.deep.7T <- do.call(rbind, myelin.compartments.7T)
myelin.superficial.deep.7T <- myelin.superficial.deep.7T %>% mutate(depth = factor(str_remove(row.names(myelin.superficial.deep.7T), "\\..*")))
myelin.superficial.deep.7T <- myelin.superficial.deep.7T %>% filter(depth != "middle")
myelin.superficial.deep.7T$depth <- factor(myelin.superficial.deep.7T$depth, levels = c("deep", "superficial"), ordered = T)

#Gam functions
source("./code/corticalmyelin_maturation/gam_models/gam_functions.R")

############################################################################################################
#### Fit GAMs to model R1-exponent relationships in deep cortex (base effect) and test for differences in the relationship in superficial cortex (interaction effect) ####

R1.aperiodic.interaction.gams <- function(input.depth.df, aperiodic.measure, output.df.name){
  
  #Combine superficial/deep R1 and EEG exponent data
  input.depth.df <- input.depth.df %>% mutate(subses = sprintf("%s_%s", sub("^sub-", "", subject_id), sub("^ses-", "", session_id))) #update subses variable to match to EEG data format 
  input.depth.df <- left_join(input.depth.df, EEG.exponent, by = "subses")
  input.depth.df$subject_id <- as.factor(input.depth.df$subject_id)
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.factorsmooth.interaction function to get interaction statistics
  gam.outputs.regionlist <- lapply(glasser.frontal$orig_parcelname, function(r){ 
    gam.factorsmooth.interaction(input.df = input.depth.df, region = as.character(r), 
                                 smooth_var = "age", smooth_var_knots = 4, smooth_covariate = gsub("-", "_", sprintf("%s_%s", r, aperiodic.measure)), smooth_covariate_knots = 3, 
                                 int_var = "depth", linear_covariates = "depth", id_var = "subject_id", random_intercepts = TRUE, set_fx = FALSE)}) 
  
  #Extract and combine base smooth effect outputs
  gam.baseeffects.df <- lapply(gam.outputs.regionlist, '[[', "gam.covsmooth.baseeffect" ) #extract this df from each region's list
  gam.baseeffects.df <- do.call(rbind, gam.baseeffects.df) #merge them into one 
  
  #Extract and combine interaction outputs
  gam.interactions.df <- lapply(gam.outputs.regionlist, '[[', "gam.covsmooth.interaction" ) #extract this df from each region's list
  gam.interactions.df <- do.call(rbind, gam.interactions.df) #merge them into one 
  
  gam.statistics.df <- list(gam.baseeffects.df, gam.interactions.df)
  names(gam.statistics.df) <- list("gam.baseeffects.df", "gam.interactions.df")
  saveRDS(gam.statistics.df, sprintf("./gam_outputs/eeg_associations/%s", output.df.name))
}

R1.aperiodic.interaction.gams(input.depth.df = myelin.superficial.deep.7T, aperiodic.measure = "exponent", output.df.name = "R1exponent_depth_interaction_glasser.RDS")
