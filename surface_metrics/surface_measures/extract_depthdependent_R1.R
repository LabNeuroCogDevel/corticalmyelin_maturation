# A script to extract depth-specific R1 measures from cortical atlas regions for the final study sample
library(dplyr)
library(tidyverse)
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/surface_metrics/surface_measures/extract_surfacestats.R")

############################################################################################################
#### Extract Depth-Dependent Regional R1 ####

# Final study sample
participants <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MP2RAGE_finalsample_demographics.csv") #created by /sample_construction/finalsample_7Tmyelin.Rmd
participants <- participants %>% mutate(subses = sprintf("%s_%s", subject_id, session_id)) #create a unique scan identifier 
  
# R1 within the cortical ribbon (10% increments)
depth.R1.measures <- list("Mean_R1map.1.00%", "Mean_R1map.0.9%", "Mean_R1map.0.8%","Mean_R1map.0.7%","Mean_R1map.0.6%","Mean_R1map.0.5%","Mean_R1map.0.4%","Mean_R1map.0.3%","Mean_R1map.0.2%", "Mean_R1map.0.1%", "Mean_R1map.0.0%") #R1 at all cortical depths

# Glasser (HCP-MMP) atlas
myelin.glasser.7T <- lapply(depth.R1.measures, function(x) {
  extract_surfacestats("glasser", x)}) #glasser atlas please
names(myelin.glasser.7T) <- list("depth_100%", "depth_90%", "depth_80%", "depth_70%", "depth_60%", "depth_50%", "depth_40%", "depth_30%", "depth_20%", "depth_10%", "depth_0%")
saveRDS(myelin.glasser.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/depthR1_glasseratlas_finalsample.RDS")

# EEG electrode atlas
myelin.electrodes.7T <- lapply(depth.R1.measures, function(x) {
  extract_surfacestats("EEGatlas", x)}) #EEG electrode regions please
names(myelin.electrodes.7T) <- list("depth_100%", "depth_90%", "depth_80%", "depth_70%", "depth_60%", "depth_50%", "depth_40%", "depth_30%", "depth_20%", "depth_10%", "depth_0%")
saveRDS(myelin.electrodes.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/depthR1_EEGatlas_finalsample.RDS")

############################################################################################################
#### Superficial, Middle, and Deep Cortex R1 ####

# Glasser (HCP-MMP) atlas
myelin.glasser.7T <- lapply(myelin.glasser.7T, function(depth){
  depth <- depth %>% mutate(subses = sprintf("%s_%s", subject_id, session_id)) 
  depth <- depth %>% select(subject_id, session_id, subses, everything())
  return(depth)})

### superficial depths
superficialR1.glasser.7T <- do.call(rbind, myelin.glasser.7T[3:4]) #20-30% of cortical thickness
superficialR1.glasser.7T$depth <- substr(row.names(superficialR1.glasser.7T), 1, 9) #assign depth
cols_to_pivot <- names(superficialR1.glasser.7T)[grep("ROI", names(superficialR1.glasser.7T))] #atlas region cols
superficialR1.glasser.7T.long <- superficialR1.glasser.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
superficialR1.glasser.7T <- superficialR1.glasser.7T.long %>% group_by(subses, region) %>% 
                        do(superficial_R1 = mean(.$R1)) %>% 
                        unnest(cols = superficial_R1) %>% 
                        pivot_wider(id_cols = subses, names_from = "region", values_from = "superficial_R1")
superficialR1.glasser.7T <- merge(superficialR1.glasser.7T, participants, by = "subses")

### middle depths 
middleR1.glasser.7T <- do.call(rbind, myelin.glasser.7T[5:7]) #40-60% of cortical thickness
middleR1.glasser.7T$depth <- substr(row.names(middleR1.glasser.7T), 1, 9) 
cols_to_pivot <- names(middleR1.glasser.7T)[grep("ROI", names(middleR1.glasser.7T))] 
middleR1.glasser.7T.long <- middleR1.glasser.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
middleR1.glasser.7T <- middleR1.glasser.7T.long %>% group_by(subses, region) %>% 
  do(middle_R1 = mean(.$R1)) %>% 
  unnest(cols = middle_R1) %>% 
  pivot_wider(id_cols = subses, names_from = "region", values_from = "middle_R1")
middleR1.glasser.7T <- merge(middleR1.glasser.7T, participants, by = "subses")

### deep depths
deepR1.glasser.7T <- do.call(rbind, myelin.glasser.7T[8:9]) #70-80% of cortical thickness
deepR1.glasser.7T$depth <- substr(row.names(deepR1.glasser.7T), 1, 9) 
cols_to_pivot <- names(deepR1.glasser.7T)[grep("ROI", names(deepR1.glasser.7T))] 
deepR1.glasser.7T.long <- deepR1.glasser.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
deepR1.glasser.7T <- deepR1.glasser.7T.long %>% group_by(subses, region) %>% 
  do(deep_R1 = mean(.$R1)) %>% 
  unnest(cols = deep_R1) %>% 
  pivot_wider(id_cols = subses, names_from = "region", values_from = "deep_R1")
deepR1.glasser.7T <- merge(deepR1.glasser.7T, participants, by = "subses")

compartments.myelin.glasser.7T <- list(superficialR1.glasser.7T, middleR1.glasser.7T, deepR1.glasser.7T)
names(compartments.myelin.glasser.7T) <- list("superficial", "middle", "deep")
saveRDS(compartments.myelin.glasser.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/compartmentsR1_glasseratlas_finalsample.RDS")

# EEG electrode atlas
myelin.electrodes.7T <- lapply(myelin.electrodes.7T, function(depth){
  depth <- depth %>% mutate(subses = sprintf("%s_%s", subject_id, session_id)) 
  depth <- depth %>% select(subject_id, session_id, subses, everything())
  return(depth)})

### superficial depths
superficialR1.electrodes.7T <- do.call(rbind, myelin.electrodes.7T[3:4]) 
superficialR1.electrodes.7T$depth <- substr(row.names(superficialR1.electrodes.7T), 1, 9) #assign depth
cols_to_pivot <- names(superficialR1.electrodes.7T)[16:69] #atlas region cols
superficialR1.electrodes.7T.long <- superficialR1.electrodes.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
superficialR1.electrodes.7T <- superficialR1.electrodes.7T.long %>% group_by(subses, region) %>% 
  do(superficial_R1 = mean(.$R1)) %>% 
  unnest(cols = superficial_R1) %>% 
  pivot_wider(id_cols = subses, names_from = "region", values_from = "superficial_R1")
superficialR1.electrodes.7T <- merge(superficialR1.electrodes.7T, participants, by = "subses")

### middle depths
middleR1.electrodes.7T <- do.call(rbind, myelin.electrodes.7T[5:7]) 
middleR1.electrodes.7T$depth <- substr(row.names(middleR1.electrodes.7T), 1, 9) #assign depth
cols_to_pivot <- names(middleR1.electrodes.7T)[16:69] #atlas region cols
middleR1.electrodes.7T.long <- middleR1.electrodes.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
middleR1.electrodes.7T <- middleR1.electrodes.7T.long %>% group_by(subses, region) %>% 
  do(middle_R1 = mean(.$R1)) %>% 
  unnest(cols = middle_R1) %>% 
  pivot_wider(id_cols = subses, names_from = "region", values_from = "middle_R1")
middleR1.electrodes.7T <- merge(middleR1.electrodes.7T, participants, by = "subses")

### deep depths
deepR1.electrodes.7T <- do.call(rbind, myelin.electrodes.7T[8:9]) 
deepR1.electrodes.7T$depth <- substr(row.names(deepR1.electrodes.7T), 1, 9) #assign depth
cols_to_pivot <- names(deepR1.electrodes.7T)[16:69] #atlas region cols
deepR1.electrodes.7T.long <- deepR1.electrodes.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
deepR1.electrodes.7T <- deepR1.electrodes.7T.long %>% group_by(subses, region) %>% 
  do(deep_R1 = mean(.$R1)) %>% 
  unnest(cols = deep_R1) %>% 
  pivot_wider(id_cols = subses, names_from = "region", values_from = "deep_R1")
deepR1.electrodes.7T <- merge(deepR1.electrodes.7T, participants, by = "subses")

compartments.myelin.electrodes.7T <- list(superficialR1.electrodes.7T, middleR1.electrodes.7T, deepR1.electrodes.7T)
names(compartments.myelin.electrodes.7T) <- list("superficial", "middle", "deep")
saveRDS(compartments.myelin.electrodes.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/compartmentsR1_EEGatlas_finalsample.RDS")
