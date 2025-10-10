#A script to fit GAMs to examine associations between superficial/deep R1, learning rate, and cognitive processing speed
library(tidyr)
library(mgcv)
library(gratia)
library(tidyverse)
library(dplyr)

############################################################################################################
#### Prepare Data and Functions ####

#Brain region list
glasser.regions <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist.csv")
glasser.frontal <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist_frontallobe.csv")

#Participant list
participants <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MP2RAGE_finalsample_demographics.csv")
participants$behave.scan.gap <- ymd(participants$mp2rage.date) - ymd(participants$behave.date)
participants <- participants %>% filter(behave.scan.gap < 360)

#Sequential learning task behavioral measures
daw.metrics <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MP2RAGE_finalsample_sequentiallearning.csv") %>% select(subject_id, session_id, age, meanrts1, meanrts2, a1, a2)
participants.daw <- left_join(participants, daw.metrics, by = c("subject_id", "session_id", "age"))
participants.daw <- participants.daw %>% filter(!is.na(a1)) #195 sessions from 131 participants

#Saccade task behavioral measures
saccade.metrics <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/merged_7t.csv") %>% select(lunaid, visitno, sess.age, antiET.cor.lat, eeg.vgsLatency_DelayAll)
colnames(saccade.metrics)[3] <- "age"
participants.saccade <- left_join(participants, saccade.metrics, by = c("lunaid", "visitno", "age"))
participants.saccade <- participants.saccade %>% filter(!is.na(antiET.cor.lat)) %>% filter(!is.na(eeg.vgsLatency_DelayAll)) #187 sessions from 125 participants

#Superficial and deep R1 measures for final study sample
myelin.compartments.7T <- readRDS("/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/compartmentsR1_glasseratlas_finalsample.RDS")
myelin.superficial.deep.7T <- do.call(rbind, myelin.compartments.7T)
myelin.superficial.deep.7T <- myelin.superficial.deep.7T %>% mutate(depth = factor(str_remove(row.names(myelin.superficial.deep.7T), "\\..*")))
myelin.superficial.deep.7T <- myelin.superficial.deep.7T %>% filter(depth != "middle")
myelin.superficial.deep.7T$depth <- factor(myelin.superficial.deep.7T$depth, levels = c("deep", "superficial"), ordered = T)

#Gam functions
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/gam_models/gam_functions.R")

############################################################################################################
#### Fit GAMs to quantify depth-specific associations between R1 and cognitive measures ####

R1.cognition.deptheffect.gams <- function(input.depth.df, input.cognitive.df, cognitive.measure, output.df.name){
  
  #Combine depth-specific R1 and cognitive measure dfs
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  input.depth.df <- merge(input.depth.df, input.cognitive.df)
  input.depth.df$subject_id <- as.factor(input.depth.df$subject_id)
  
  #Run the gam.covariatesmooth.maineffect function 
  gam.outputs.regionlist <- lapply(glasser.frontal$orig_parcelname, function(r){  
    gam.covariatesmooth.maineffect(input.df = input.depth.df, region = as.character(r), 
                                   smooth_var = "age", smooth_var_knots = 4, smooth_covariate = cognitive.measure, smooth_covariate_knots = 3, 
                                   linear_covariates = "NA", id_var = "subject_id", random_intercepts = TRUE, set_fx = FALSE)}) 
  
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
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/cognitive_associations/%s", output.df.name))
  
  #Clean up
  gc(gam.outputs.statslist)
}

## Reaction time - stage 1
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$superficial, input.cognitive.df = participants.daw, cognitive.measure = "meanrts1", output.df.name = "rt1_superficial_statistics.RDS")
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$deep, input.cognitive.df = participants.daw, cognitive.measure = "meanrts1", output.df.name = "rt1_deep_statistics.RDS")

## Reaction time - stage 2
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$superficial, input.cognitive.df = participants.daw, cognitive.measure = "meanrts2", output.df.name = "rt2_superficial_statistics.RDS")
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$deep, input.cognitive.df = participants.daw, cognitive.measure = "meanrts2", output.df.name = "rt2_deep_statistics.RDS")

## Learning rate - stage 1
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$superficial, input.cognitive.df = participants.daw, cognitive.measure = "a1", output.df.name = "a1_superficial_statistics.RDS")
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$deep, input.cognitive.df = participants.daw, cognitive.measure = "a1", output.df.name = "a1_deep_statistics.RDS")

## Learning rate - stage 2
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$superficial, input.cognitive.df = participants.daw, cognitive.measure = "a2", output.df.name = "a2_superficial_statistics.RDS")
R1.cognition.deptheffect.gams(input.depth.df = myelin.compartments.7T$deep, input.cognitive.df = participants.daw, cognitive.measure = "a2", output.df.name = "a2_deep_statistics.RDS")

############################################################################################################
#### Fit GAMs to statistically test whether associations between R1 and cognitive measures differ by depth (depth interactions) ####

R1.cognition.depthinteraction.gams <- function(input.depth.df, input.cognitive.df, cognitive.measure, output.df.name){
  
  #Combine superficial/deep R1 and cognitive measure dfs
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  input.depth.df <- merge(input.depth.df, input.cognitive.df)
  input.depth.df$subject_id <- as.factor(input.depth.df$subject_id)
  
  #Run the gam.factorsmooth.interaction function to get interaction statistics
  gam.outputs.regionlist <- lapply(glasser.frontal$orig_parcelname, function(r){ 
    gam.factorsmooth.interaction(input.df = input.depth.df, region = as.character(r), 
                                 smooth_var = "age", smooth_var_knots = 4, smooth_covariate = cognitive.measure, smooth_covariate_knots = 3, 
                                 int_var = "depth", linear_covariates = "depth", id_var = "subject_id", random_intercepts = TRUE, set_fx = FALSE)}) 
  
  #Extract and combine base smooth effect outputs
  gam.baseeffects.df <- lapply(gam.outputs.regionlist, '[[', "gam.covsmooth.baseeffect" ) #extract this df from each region's list
  gam.baseeffects.df <- do.call(rbind, gam.baseeffects.df) #merge them into one 
  
  #Extract and combine interaction outputs
  gam.interactions.df <- lapply(gam.outputs.regionlist, '[[', "gam.covsmooth.interaction" ) #extract this df from each region's list
  gam.interactions.df <- do.call(rbind, gam.interactions.df) #merge them into one 
  
  gam.statistics.df <- list(gam.baseeffects.df, gam.interactions.df)
  names(gam.statistics.df) <- list("gam.baseeffects.df", "gam.interactions.df")
  saveRDS(gam.statistics.df, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/cognitive_associations/%s", output.df.name))
}

## Reaction time - stage 1
R1.cognition.depthinteraction.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "meanrts1", output.df.name = "rt1_depthinteraction.RDS")

## Reaction time - stage 2
R1.cognition.depthinteraction.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "meanrts2", output.df.name = "rt2_depthinteraction.RDS")

## Learning rate - stage 1
R1.cognition.depthinteraction.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "a1", output.df.name = "a1_depthinteraction.RDS")

## Learning rate - stage 2
R1.cognition.depthinteraction.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "a2", output.df.name = "a2_depthinteraction.RDS")

############################################################################################################
#### Fit GAMs to quantify associations between R1 and cognitive measures across superficial and deep cortex ####

R1.cognition.maineffect.gams <- function(input.depth.df, input.cognitive.df, cognitive.measure, output.df.name){
  
  #Combine superficial/deep R1 and cognitive measure dfs
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  input.depth.df <- merge(input.depth.df, input.cognitive.df)
  input.depth.df$subject_id <- as.factor(input.depth.df$subject_id)
  
  #Run the gam.covariatesmooth.maineffect function 
  gam.outputs.regionlist <- lapply(glasser.frontal$orig_parcelname, function(r){  
    gam.covariatesmooth.maineffect(input.df = input.depth.df, region = as.character(r), 
                                   smooth_var = "age", smooth_var_knots = 4, smooth_covariate = cognitive.measure, smooth_covariate_knots = 3, 
                                   linear_covariates = "depth", id_var = "subject_id", random_intercepts = TRUE, set_fx = FALSE)}) 
  
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
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/cognitive_associations/%s", output.df.name))
  
  #Clean up
  gc(gam.outputs.statslist)
}

## Reaction time - stage 1
R1.cognition.maineffect.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "meanrts1", output.df.name = "rt1_SGIGdepths_maineffect.RDS")

## Reaction time - stage 2
R1.cognition.maineffect.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "meanrts2", output.df.name = "rt2_SGIGdepths_maineffect.RDS")

## Learning rate - stage 1
R1.cognition.maineffect.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "a1", output.df.name = "a1_SGIGdepths_maineffect.RDS")

## Learning rate - stage 2
R1.cognition.maineffect.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.daw, cognitive.measure = "a2", output.df.name = "a2_SGIGdepths_maineffect.RDS")

## Antisaccade
R1.cognition.maineffect.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.saccade, cognitive.measure = "antiET.cor.lat", output.df.name = "antilatency_SGIGdepths_maineffect.RDS")

## VGS
R1.cognition.maineffect.gams(input.depth.df = myelin.superficial.deep.7T, input.cognitive.df = participants.saccade, cognitive.measure = "eeg.vgsLatency_DelayAll", output.df.name = "vgslatency_SGIGdepths_maineffect.RDS")