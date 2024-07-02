#A script to fit GAMs to R1 data in different regions and at different cortical depths, delineating depth-specific myelin growth trajectories
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

myelin.glasser.7T <- lapply(myelin.glasser.7T, function(depth){
  depth <- depth %>% mutate(subject_id = as.factor(subject_id)) #factor
  depth <- depth %>% mutate(sex = as.factor(sex)) #factor
  depth <- depth %>% mutate(osex = ordered(sex, levels = c("M", "F"))) #M <  F, obvi
  return(depth)
})

#Superficial and deep R1 measures for final study sample
SGIGmyelin.glasser.7T <- readRDS("/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/SGIGR1_glasseratlas_finalsample.RDS")

SGIGmyelin.glasser.7T <- lapply(SGIGmyelin.glasser.7T, function(depth){
  depth <- depth %>% mutate(subject_id = as.factor(subject_id)) #factor
  return(depth)
})

#Gam functions
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/gam_models/gam_functions.R")

############################################################################################################
#### Fit developmental GAMs and save out statistics, fitted values, smooths, and derivatives ####

## Age-only models

run.gams.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.statistics.smooths function on every region for R1 data in this input.depth.df
  gam.outputs.regionlist <- lapply(glasser.regions$orig_parcelname, function(r){  #list of gam results, list elements are regions
                      gam.statistics.smooths(input.df = input.depth.df, region = as.character(r), 
                                      smooth_var = "age", id_var = "subject_id", covariates = "NA", 
                                      random_intercepts = TRUE, random_slopes = FALSE, knots = 4, set_fx = FALSE)}) 

  #Extract and combine gam statistics ouputs
  gam.statistics.df <- lapply(gam.outputs.regionlist, '[[', "gam.statistics" ) #extract this df from each region's list
  gam.statistics.df <- do.call(rbind, gam.statistics.df) #merge them into one 
  
  #Extract and combine fitted values 
  gam.fittedvalues.df <- lapply(gam.outputs.regionlist, '[[', "gam.fittedvalues" ) #extract this df from each region's list
  gam.fittedvalues.df <- do.call(rbind, gam.fittedvalues.df) #merge them into one 
  
  #Extract and combine smooth estimates
  gam.smoothestimates.df <- lapply(gam.outputs.regionlist, '[[', "gam.smoothestimates" ) #extract this df from each region's list
  gam.smoothestimates.df <- do.call(rbind, gam.smoothestimates.df) #merge them into one 
  
  #Extract and combine derivatives
  gam.derivatives.df <- lapply(gam.outputs.regionlist, '[[', "gam.derivatives" ) #extract this df from each region's list
  gam.derivatives.df <- do.call(rbind, gam.derivatives.df) #merge them into one 
  
  #Save depth-specific results as an RDS
  gam.outputs.statslist <- list(gam.statistics.df, gam.fittedvalues.df, gam.smoothestimates.df, gam.derivatives.df) #list of gam results, list elements are stats dfs binded across regions
  names(gam.outputs.statslist) <- list("gam.statistics.df", "gam.fittedvalues.df", "gam.smoothestimates.df", "gam.derivatives.df")
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/developmental_effects/%s", output.df.name))

  #Clean up
  gc(gam.outputs.statslist)
  }

run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_1, output.df.name = "depth1_gamstatistics_age.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_2, output.df.name = "depth2_gamstatistics_age.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_3, output.df.name = "depth3_gamstatistics_age.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_4, output.df.name = "depth4_gamstatistics_age.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_5, output.df.name = "depth5_gamstatistics_age.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_6, output.df.name = "depth6_gamstatistics_age.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_7, output.df.name = "depth7_gamstatistics_age.RDS")

run.gams.bydepth(input.depth.df = SGIGmyelin.glasser.7T$superficial, output.df.name = "superficialcortex_gamstatistics_age.RDS")
run.gams.bydepth(input.depth.df = SGIGmyelin.glasser.7T$deep, output.df.name = "deepcortex_gamstatistics_age.RDS")

## Age models covaried for sex

run.gams.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.statistics.smooths function on every region for R1 data in this input.depth.df
  gam.outputs.regionlist <- lapply(glasser.regions$orig_parcelname, function(r){  #list of gam results, list elements are regions
    gam.statistics.smooths(input.df = input.depth.df, region = as.character(r), 
                           smooth_var = "age", id_var = "subject_id", covariates = "sex", 
                           random_intercepts = TRUE, random_slopes = FALSE, knots = 4, set_fx = FALSE)}) 
  
  #Extract and combine gam statistics ouputs
  gam.statistics.df <- lapply(gam.outputs.regionlist, '[[', "gam.statistics" ) #extract this df from each region's list
  gam.statistics.df <- do.call(rbind, gam.statistics.df) #merge them into one 
  
  #Extract and combine fitted values 
  gam.fittedvalues.df <- lapply(gam.outputs.regionlist, '[[', "gam.fittedvalues" ) #extract this df from each region's list
  gam.fittedvalues.df <- do.call(rbind, gam.fittedvalues.df) #merge them into one 
  
  #Extract and combine smooth estimates
  gam.smoothestimates.df <- lapply(gam.outputs.regionlist, '[[', "gam.smoothestimates" ) #extract this df from each region's list
  gam.smoothestimates.df <- do.call(rbind, gam.smoothestimates.df) #merge them into one 
  
  #Extract and combine derivatives
  gam.derivatives.df <- lapply(gam.outputs.regionlist, '[[', "gam.derivatives" ) #extract this df from each region's list
  gam.derivatives.df <- do.call(rbind, gam.derivatives.df) #merge them into one 
  
  #Save depth-specific results as an RDS
  gam.outputs.statslist <- list(gam.statistics.df, gam.fittedvalues.df, gam.smoothestimates.df, gam.derivatives.df) #list of gam results, list elements are stats dfs binded across regions
  names(gam.outputs.statslist) <- list("gam.statistics.df", "gam.fittedvalues.df", "gam.smoothestimates.df", "gam.derivatives.df")
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/developmental_effects/%s", output.df.name))
  
  #Clean up
  gc(gam.outputs.statslist)
}

run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_1, output.df.name = "depth1_gamstatistics_age_sex.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_2, output.df.name = "depth2_gamstatistics_age_sex.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_3, output.df.name = "depth3_gamstatistics_age_sex.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_4, output.df.name = "depth4_gamstatistics_age_sex.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_5, output.df.name = "depth5_gamstatistics_age_sex.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_6, output.df.name = "depth6_gamstatistics_age_sex.RDS")
run.gams.bydepth(input.depth.df = myelin.glasser.7T$depth_7, output.df.name = "depth7_gamstatistics_age_sex.RDS")

############################################################################################################
#### Fit sex effect GAMs and save out main effect statistics ####

fit.sexeffects.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.linearcovariate.maineffect function on every region for R1 data in this input.depth.df
  gam.sex.statistics <- lapply(glasser.regions$orig_parcelname, function(r){  #list of gam results, list elements are regions
    gam.linearcovariate.maineffect(input.df = input.depth.df, region = as.character(r), 
                           smooth_var = "age", id_var = "subject_id", covariates = "osex", 
                           random_intercepts = TRUE, random_slopes = FALSE, knots = 4, set_fx = FALSE)}) 
  
  gam.sex.statistics <- do.call(rbind, gam.sex.statistics) #merge them into one df
  
  #Save depth-specific results as an RDS
  saveRDS(gam.sex.statistics, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/sex_effects/%s", output.df.name))
  
  #Clean up
  gc(gam.sex.statistics)
}

fit.sexeffects.bydepth(input.depth.df = myelin.glasser.7T$depth_1, output.df.name = "depth1_sex_maineffects.RDS")
fit.sexeffects.bydepth(input.depth.df = myelin.glasser.7T$depth_2, output.df.name = "depth2_sex_maineffects.RDS")
fit.sexeffects.bydepth(input.depth.df = myelin.glasser.7T$depth_3, output.df.name = "depth3_sex_maineffects.RDS")
fit.sexeffects.bydepth(input.depth.df = myelin.glasser.7T$depth_4, output.df.name = "depth4_sex_maineffects.RDS")
fit.sexeffects.bydepth(input.depth.df = myelin.glasser.7T$depth_5, output.df.name = "depth5_sex_maineffects.RDS")
fit.sexeffects.bydepth(input.depth.df = myelin.glasser.7T$depth_6, output.df.name = "depth6_sex_maineffects.RDS")
fit.sexeffects.bydepth(input.depth.df = myelin.glasser.7T$depth_7, output.df.name = "depth7_sex_maineffects.RDS")

############################################################################################################
#### Fit age-by-sex interaction GAMs and save out interaction statistics ####

fit.agesexinteraction.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.factorsmooth.interaction function on every region for R1 data in this input.depth.df
  gam.agebysex.statistics <- lapply(glasser.regions$orig_parcelname, function(r){  #list of gam results, list elements are regions
    gam.factorsmooth.interaction(input.df = input.depth.df, region = as.character(r), 
                                   smooth_var = "age", id_var = "subject_id", int_var = "osex", covariates = "osex", 
                                   random_intercepts = TRUE, random_slopes = FALSE, knots = 4, set_fx = FALSE)}) 
  
  gam.agebysex.statistics <- do.call(rbind, gam.agebysex.statistics) #merge them into one df
  
  #Save depth-specific results as an RDS
  saveRDS(gam.agebysex.statistics, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/sex_effects/%s", output.df.name))
  
  #Clean up
  gc(gam.agebysex.statistics)
}

fit.agesexinteraction.bydepth(input.depth.df = myelin.glasser.7T$depth_1, output.df.name = "depth1_sex_ageinteraction.RDS")
fit.agesexinteraction.bydepth(input.depth.df = myelin.glasser.7T$depth_2, output.df.name = "depth2_sex_ageinteraction.RDS")
fit.agesexinteraction.bydepth(input.depth.df = myelin.glasser.7T$depth_3, output.df.name = "depth3_sex_ageinteraction.RDS")
fit.agesexinteraction.bydepth(input.depth.df = myelin.glasser.7T$depth_4, output.df.name = "depth4_sex_ageinteraction.RDS")
fit.agesexinteraction.bydepth(input.depth.df = myelin.glasser.7T$depth_5, output.df.name = "depth5_sex_ageinteraction.RDS")
fit.agesexinteraction.bydepth(input.depth.df = myelin.glasser.7T$depth_6, output.df.name = "depth6_sex_ageinteraction.RDS")
fit.agesexinteraction.bydepth(input.depth.df = myelin.glasser.7T$depth_7, output.df.name = "depth7_sex_ageinteraction.RDS")

