#A script to conduct R1 development sensitivity analyses
library(tidyr)
library(mgcv)
library(gratia)
library(tidyverse)
library(dplyr)
library(arrow)

############################################################################################################
#### Prepare Data and Functions ####

#Brain region list
glasser.regions <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist.csv")

#Superficial, middle, and deep R1 for final study sample
myelin.compartments.7T <- readRDS("/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/compartmentsR1_glasseratlas_finalsample.RDS")

myelin.compartments.7T <- lapply(myelin.compartments.7T, function(depth){
  depth <- depth %>% mutate(subject_id = as.factor(subject_id)) #factor
  depth <- depth %>% mutate(sex = as.factor(sex)) #factor
  depth <- depth %>% mutate(osex = ordered(sex, levels = c("M", "F"))) #M <  F, obvi
  return(depth)
})

#Gam functions
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/gam_models/gam_functions.R")

############################################################################################################
#### Fit developmental GAMs and save out statistics, fitted values, smooths, and derivatives ####

## STRUCTURAL QUALITY CONTROL: Age models controlling for structural data/surface reconstruction quality (Euler number)

#Read in Euler number
fs.qc <- read_parquet("/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/7T_BrainMechanisms_brainmeasures.parquet") %>% select(subject_id, session_id, lh_euler, rh_euler) #Euler numbers from fstabulate
fs.qc$session_id <- gsub('.{15}$', '', fs.qc$session_id) #format session_id to remove long.sub-id from the session name (just keep ses-date)
fs.qc$euler_number <- fs.qc %>% select(lh_euler, rh_euler) %>% rowMeans() #calculate mean euler number across hemispheres to include as a covariate in developmental models
myelin.compartments.7T <- lapply(myelin.compartments.7T, function(depth){
  depth <- merge(depth, fs.qc, by = c("subject_id", "session_id"))
  return(depth)
})

#Fit gams
run.eulergams.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.statistics.smooths function on every region for R1 data in this input.depth.df
  gam.outputs.regionlist <- lapply(glasser.regions$orig_parcelname, function(r){  #list of gam results, list elements are regions
    gam.statistics.smooths(input.df = input.depth.df, region = as.character(r), 
                           smooth_var = "age", id_var = "subject_id", covariates = "euler_number", 
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
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/sensitivity_analyses/%s", output.df.name))
  
  #Clean up
  gc(gam.outputs.statslist)
}

run.eulergams.bydepth(input.depth.df = myelin.compartments.7T$superficial, output.df.name = "superficial_gamstatistics_age_euler.RDS")
run.eulergams.bydepth(input.depth.df = myelin.compartments.7T$middle, output.df.name = "middle_gamstatistics_age_euler.RDS")
run.eulergams.bydepth(input.depth.df = myelin.compartments.7T$deep, output.df.name = "deep_gamstatistics_age_euler.RDS")

## CORTICAL THICKNESS CONTROL: Age models controlling for regional cortical thickness 

#Extract cortical thickness measures
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/surface_metrics/surface_measures/extract_surfacestats.R")
ct <- extract_surfacestats(myatlas = "glasser", mymeasure = "ThickAvg") %>% select("subject_id", "session_id", "lunaid", "visitno", contains("ROI")) #cortical thickness of each glasser region from fstabule
ct <- ct %>%
  rename_with(~ ifelse(str_ends(., "ROI"), paste0(., "_CT"), .)) #append _CT to column names so we can specify as covariate in developmental models
myelinCT.compartments.7T <- lapply(myelin.compartments.7T, function(depth){
  depth <- merge(depth, ct, by = c("subject_id", "session_id", "lunaid", "visitno"), sort = F)
  return(depth)
})

#Fit gams
run.CTgams.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.statistics.smooths function on every region for R1 data in this input.depth.df
  gam.outputs.regionlist <- lapply(glasser.regions$orig_parcelname, function(r){  
    gam.statistics.smooths(input.df = input.depth.df, region = as.character(r), 
                           smooth_var = "age", id_var = "subject_id", covariates = gsub("-", "_", sprintf("%s_CT", r)), 
                           random_intercepts = TRUE, random_slopes = FALSE, knots = 4, set_fx = FALSE)}) 
  
  #Extract and combine gam statistics ouputs
  gam.statistics.df <- lapply(gam.outputs.regionlist, '[[', "gam.statistics" ) 
  gam.statistics.df <- do.call(rbind, gam.statistics.df)
  
  #Extract and combine fitted values 
  gam.fittedvalues.df <- lapply(gam.outputs.regionlist, '[[', "gam.fittedvalues" ) 
  gam.fittedvalues.df <- do.call(rbind, gam.fittedvalues.df) 
  
  #Extract and combine smooth estimates
  gam.smoothestimates.df <- lapply(gam.outputs.regionlist, '[[', "gam.smoothestimates" )
  gam.smoothestimates.df <- do.call(rbind, gam.smoothestimates.df)
  
  #Extract and combine derivatives
  gam.derivatives.df <- lapply(gam.outputs.regionlist, '[[', "gam.derivatives" )
  gam.derivatives.df <- do.call(rbind, gam.derivatives.df)
  
  #Save depth-specific results as an RDS
  gam.outputs.statslist <- list(gam.statistics.df, gam.fittedvalues.df, gam.smoothestimates.df, gam.derivatives.df) 
  names(gam.outputs.statslist) <- list("gam.statistics.df", "gam.fittedvalues.df", "gam.smoothestimates.df", "gam.derivatives.df")
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/sensitivity_analyses/%s", output.df.name))
  
  #Clean up
  gc(gam.outputs.statslist)
}

run.CTgams.bydepth(input.depth.df = myelinCT.compartments.7T$superficial, output.df.name = "superficial_gamstatistics_age_CT.RDS")
run.CTgams.bydepth(input.depth.df = myelinCT.compartments.7T$middle, output.df.name = "middle_gamstatistics_age_CT.RDS")
run.CTgams.bydepth(input.depth.df = myelinCT.compartments.7T$deep, output.df.name = "deep_gamstatistics_age_CT.RDS")

## CURVATURE (GYRUS/SULCUS) CONTROL: Age models controlling for regional mean curvature, which captures folding properties and gyral versus sulcal location

#Extract mean curvature measures
curv <- extract_surfacestats(myatlas = "glasser", mymeasure = "MeanCurv") %>% select("subject_id", "session_id", "lunaid", "visitno", contains("ROI")) #mean curvature of each glasser region from fstabule
curv <- curv %>%
  rename_with(~ ifelse(str_ends(., "ROI"), paste0(., "_CURV"), .)) #append _CURV to column names so we can specify as covariate in developmental models
myelincurvature.compartments.7T <- lapply(myelin.compartments.7T, function(depth){
  depth <- merge(depth, curv, by = c("subject_id", "session_id", "lunaid", "visitno"), sort = F)
  return(depth)
})

#Fit gams
run.CURVgams.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.statistics.smooths function on every region for R1 data in this input.depth.df
  gam.outputs.regionlist <- lapply(glasser.regions$orig_parcelname, function(r){  
    gam.statistics.smooths(input.df = input.depth.df, region = as.character(r), 
                           smooth_var = "age", id_var = "subject_id", covariates = gsub("-", "_", sprintf("%s_CURV", r)), 
                           random_intercepts = TRUE, random_slopes = FALSE, knots = 4, set_fx = FALSE)}) 
  
  #Extract and combine gam statistics ouputs
  gam.statistics.df <- lapply(gam.outputs.regionlist, '[[', "gam.statistics" ) 
  gam.statistics.df <- do.call(rbind, gam.statistics.df)
  
  #Extract and combine fitted values 
  gam.fittedvalues.df <- lapply(gam.outputs.regionlist, '[[', "gam.fittedvalues" ) 
  gam.fittedvalues.df <- do.call(rbind, gam.fittedvalues.df) 
  
  #Extract and combine smooth estimates
  gam.smoothestimates.df <- lapply(gam.outputs.regionlist, '[[', "gam.smoothestimates" )
  gam.smoothestimates.df <- do.call(rbind, gam.smoothestimates.df)
  
  #Extract and combine derivatives
  gam.derivatives.df <- lapply(gam.outputs.regionlist, '[[', "gam.derivatives" )
  gam.derivatives.df <- do.call(rbind, gam.derivatives.df)
  
  #Save depth-specific results as an RDS
  gam.outputs.statslist <- list(gam.statistics.df, gam.fittedvalues.df, gam.smoothestimates.df, gam.derivatives.df) 
  names(gam.outputs.statslist) <- list("gam.statistics.df", "gam.fittedvalues.df", "gam.smoothestimates.df", "gam.derivatives.df")
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/sensitivity_analyses/%s", output.df.name))
  
  #Clean up
  gc(gam.outputs.statslist)
}

run.CURVgams.bydepth(input.depth.df = myelincurvature.compartments.7T$superficial, output.df.name = "superficial_gamstatistics_age_curvature.RDS")
run.CURVgams.bydepth(input.depth.df = myelincurvature.compartments.7T$middle, output.df.name = "middle_gamstatistics_age_curvature.RDS")
run.CURVgams.bydepth(input.depth.df = myelincurvature.compartments.7T$deep, output.df.name = "deep_gamstatistics_age_curvature.RDS")

## CORTEX PARTIAL VOLUME CONTROL: Age models controlling for CSF and WM partial volume effects

#Extract cortex pve measures for each cortical depth
participants <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MP2RAGE_finalsample_demographics.csv")
cortexpve <- read_parquet("/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/7T_BrainMechanisms_cortexpve.parquet") #parque with cortex fraction measures
cortexpve <- cortexpve %>% filter(atlas == "glasser") #glasser atlas 
cortexpve <- cortexpve %>% filter(StructName != "???") #remove non-region 

extract_depth_cortexpve <- function(mymeasure){
  measure.df <- cortexpve %>% select(subject_id, session_id, StructName, all_of(mymeasure))
  measure.df <- measure.df %>% pivot_wider(names_from = "StructName", values_from = all_of(mymeasure), values_fn = mean)
  measure.df <- merge(participants, measure.df, by = c("subject_id", "session_id"), sort = F)
  return(measure.df)}

pve.measures <- list("Mean_cortexpve.0.8%","Mean_cortexpve.0.7%","Mean_cortexpve.0.6%","Mean_cortexpve.0.5%","Mean_cortexpve.0.4%","Mean_cortexpve.0.3%","Mean_cortexpve.0.2%") #measures to extract data for 
cortexpve.glasser.7T <- lapply(pve.measures, function(x) { #cortex fraction measures for each participant/region/cortical depth
  extract_depth_cortexpve(x)}) 
names(cortexpve.glasser.7T) <- list("depth_1", "depth_2", "depth_3", "depth_4", "depth_5", "depth_6", "depth_7")

#Calculate average cortex volume fraction in superficial, middle, and deep compartments for each region
cortexpve.superficial <- do.call(rbind, cortexpve.glasser.7T[1:2]) 
cols_to_pivot <- names(cortexpve.superficial)[grep("ROI", names(cortexpve.superficial))] #atlas region cols
cortexpve.superficial <-cortexpve.superficial %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "cortex.fraction") 
cortexpve.superficial <- cortexpve.superficial %>% group_by(subject_id, session_id, region) %>% 
  do(cortex.fraction = mean(.$cortex.fraction)) %>% 
  unnest(cols = cortex.fraction) %>% 
  pivot_wider(id_cols = c("subject_id", "session_id"), names_from = "region", values_from = "cortex.fraction")

cortexpve.middle <- do.call(rbind, cortexpve.glasser.7T[3:5]) 
cortexpve.middle <- cortexpve.middle %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "cortex.fraction")
cortexpve.middle <- cortexpve.middle %>% group_by(subject_id, session_id, region) %>% 
  do(cortex.fraction = mean(.$cortex.fraction)) %>% 
  unnest(cols = cortex.fraction) %>% 
  pivot_wider(id_cols = c("subject_id", "session_id"), names_from = "region", values_from = "cortex.fraction")

cortexpve.deep <- do.call(rbind, cortexpve.glasser.7T[6:7]) 
cortexpve.deep <- cortexpve.deep %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "cortex.fraction")
cortexpve.deep <- cortexpve.deep %>% group_by(subject_id, session_id, region) %>% 
  do(cortex.fraction = mean(.$cortex.fraction)) %>% 
  unnest(cols = cortex.fraction) %>% 
  pivot_wider(id_cols = c("subject_id", "session_id"), names_from = "region", values_from = "cortex.fraction")

cortexpve.compartments.7T <- list(cortexpve.superficial, cortexpve.middle, cortexpve.deep)
names(cortexpve.compartments.7T) <- c("superficial", "middle", "deep")

cortexpve.compartments.7T <- lapply(cortexpve.compartments.7T, function(depth){
  depth <- depth %>% rename_with(~ ifelse(str_ends(., "ROI"), paste0(., "_PVE"), .)) #append _PVE to column names so we can specify as a covariate in developmental models
  return(depth)
})

#Merge R1 data with cortex pve measure for each cortical compartment
myelinPVE.compartments.7T <- myelin.compartments.7T #initiate by duplicating prior to merging
myelinPVE.compartments.7T$superficial <- merge(myelinPVE.compartments.7T$superficial, cortexpve.compartments.7T$superficial, by = c("subject_id", "session_id"), sort = F)
myelinPVE.compartments.7T$middle <- merge(myelinPVE.compartments.7T$middle, cortexpve.compartments.7T$middle, by = c("subject_id", "session_id"), sort = F)
myelinPVE.compartments.7T$deep <- merge(myelinPVE.compartments.7T$deep, cortexpve.compartments.7T$deep, by = c("subject_id", "session_id"), sort = F)

#Fit gams
run.PVEgams.bydepth <- function(input.depth.df, output.df.name){
  
  names(input.depth.df) <- gsub("-", "_", names(input.depth.df))
  
  #Run the gam.statistics.smooths function on every region for R1 data in this input.depth.df
  gam.outputs.regionlist <- lapply(glasser.regions$orig_parcelname, function(r){  
    gam.statistics.smooths(input.df = input.depth.df, region = as.character(r), 
                           smooth_var = "age", id_var = "subject_id", covariates = gsub("-", "_", sprintf("%s_PVE", r)), 
                           random_intercepts = TRUE, random_slopes = FALSE, knots = 4, set_fx = FALSE)}) 
  
  #Extract and combine gam statistics ouputs
  gam.statistics.df <- lapply(gam.outputs.regionlist, '[[', "gam.statistics" ) 
  gam.statistics.df <- do.call(rbind, gam.statistics.df)
  
  #Extract and combine fitted values 
  gam.fittedvalues.df <- lapply(gam.outputs.regionlist, '[[', "gam.fittedvalues" ) 
  gam.fittedvalues.df <- do.call(rbind, gam.fittedvalues.df) 
  
  #Extract and combine smooth estimates
  gam.smoothestimates.df <- lapply(gam.outputs.regionlist, '[[', "gam.smoothestimates" )
  gam.smoothestimates.df <- do.call(rbind, gam.smoothestimates.df)
  
  #Extract and combine derivatives
  gam.derivatives.df <- lapply(gam.outputs.regionlist, '[[', "gam.derivatives" )
  gam.derivatives.df <- do.call(rbind, gam.derivatives.df)
  
  #Save depth-specific results as an RDS
  gam.outputs.statslist <- list(gam.statistics.df, gam.fittedvalues.df, gam.smoothestimates.df, gam.derivatives.df) 
  names(gam.outputs.statslist) <- list("gam.statistics.df", "gam.fittedvalues.df", "gam.smoothestimates.df", "gam.derivatives.df")
  saveRDS(gam.outputs.statslist, sprintf("/Volumes/Hera/Projects/corticalmyelin_development/gam_outputs/sensitivity_analyses/%s", output.df.name))
  
  #Clean up
  gc(gam.outputs.statslist)
}

run.PVEgams.bydepth(input.depth.df = myelinPVE.compartments.7T$superficial, output.df.name = "superficial_gamstatistics_age_PVE.RDS")
run.PVEgams.bydepth(input.depth.df = myelinPVE.compartments.7T$middle, output.df.name = "middle_gamstatistics_age_PVE.RDS")
run.PVEgams.bydepth(input.depth.df = myelinPVE.compartments.7T$deep, output.df.name = "deep_gamstatistics_age_PVE.RDS")