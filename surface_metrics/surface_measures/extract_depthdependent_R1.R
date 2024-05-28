# A script to extract depth-specific R1 measures from cortical atlas regions for the final study sample
library(dplyr)
library(tidyverse)
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/surface_metrics/surface_measures/extract_surfacestats.R")

############################################################################################################
#### Extract Depth-Dependent Regional R1 ####

# Final study sample
participants <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MP2RAGE_finalsample_demographics.csv") #created by /sample_construction/finalsample_7Tmyelin.Rmd
participants <- participants %>% mutate(subses = sprintf("%s_%s", subject_id, session_id)) #create a unique scan identifier 
  
# Myelin measures
mean.myelin.measures <- list("Mean_R1map.0.8%","Mean_R1map.0.7%","Mean_R1map.0.6%","Mean_R1map.0.5%","Mean_R1map.0.4%","Mean_R1map.0.3%","Mean_R1map.0.2%") #measures to extract data for 

# Glasser (HCP-MMP) atlas
myelin.glasser.7T <- lapply(mean.myelin.measures, function(x) {
  extract_surfacestats("glasser", x)}) #glasser atlas please
names(myelin.glasser.7T) <- list("depth_1", "depth_2", "depth_3", "depth_4", "depth_5", "depth_6", "depth_7")
saveRDS(myelin.glasser.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/depthR1_glasseratlas_finalsample.RDS")

# EEG electrode atlas
myelin.electrodes.7T <- lapply(mean.myelin.measures, function(x) {
  extract_surfacestats("EEGatlas", x)}) #EEG electrode regions please
names(myelin.electrodes.7T) <- list("depth_1", "depth_2", "depth_3", "depth_4", "depth_5", "depth_6", "depth_7")
saveRDS(myelin.electrodes.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/depthR1_EEGatlas_finalsample.RDS")

############################################################################################################
#### Calculate Superficial and Deep R1 ####

# Glasser (HCP-MMP) atlas
myelin.glasser.7T <- lapply(myelin.glasser.7T, function(depth){
  depth <- depth %>% mutate(subses = sprintf("%s_%s", subject_id, session_id)) 
  depth <- depth %>% select(subject_id, session_id, subses, everything())
  return(depth)})

### superficial depths
SGmyelin.glasser.7T <- do.call(rbind, myelin.glasser.7T[1:3]) #merge data for top 3 depths
SGmyelin.glasser.7T$depth <- substr(row.names(SGmyelin.glasser.7T), 1, 7) #assign depth
cols_to_pivot <- names(SGmyelin.glasser.7T)[grep("ROI", names(SGmyelin.glasser.7T))] #atlas region cols
SGmyelin.glasser.7T.long <- SGmyelin.glasser.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
SGmyelin.glasser.7T <- SGmyelin.glasser.7T.long %>% group_by(subses, region) %>% #mean R1 in depths 1-3 for each region
                        do(superficial_R1 = mean(.$R1)) %>% 
                        unnest(cols = superficial_R1) %>% 
                        pivot_wider(id_cols = subses, names_from = "region", values_from = "superficial_R1")
SGmyelin.glasser.7T <- merge(SGmyelin.glasser.7T, participants, by = "subses")

### deep depths
IGmyelin.glasser.7T <- do.call(rbind, myelin.glasser.7T[4:7]) #merge data for bottom 4 depths
IGmyelin.glasser.7T$depth <- substr(row.names(IGmyelin.glasser.7T), 1, 7) 
cols_to_pivot <- names(IGmyelin.glasser.7T)[grep("ROI", names(IGmyelin.glasser.7T))] 
IGmyelin.glasser.7T.long <- IGmyelin.glasser.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") 
IGmyelin.glasser.7T <- IGmyelin.glasser.7T.long %>% group_by(subses, region) %>% #mean R1 in depths 4-7 for each region
                        do(deep_R1 = mean(.$R1)) %>% 
                        unnest(cols = deep_R1) %>% 
                        pivot_wider(id_cols = subses, names_from = "region", values_from = "deep_R1")
IGmyelin.glasser.7T <- merge(IGmyelin.glasser.7T, participants, by = "subses")

SGIGmyelin.glasser.7T <- list(SGmyelin.glasser.7T, IGmyelin.glasser.7T)
names(SGIGmyelin.glasser.7T) <- list("superficial", "deep")
saveRDS(SGIGmyelin.glasser.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/SGIGR1_glasseratlas_finalsample.RDS")

# EEG electrode atlas
myelin.electrodes.7T <- lapply(myelin.electrodes.7T, function(depth){
  depth <- depth %>% mutate(subses = sprintf("%s_%s", subject_id, session_id)) 
  depth <- depth %>% select(subject_id, session_id, subses, everything())
  return(depth)})

### superficial depths
SGmyelin.electrodes.7T <- do.call(rbind, myelin.electrodes.7T[1:3]) #merge data for top 3 depths
SGmyelin.electrodes.7T$depth <- substr(row.names(SGmyelin.electrodes.7T), 1, 7) #assign depth
cols_to_pivot <- names(SGmyelin.electrodes.7T)[16:75] #atlas region cols
SGmyelin.electrodes.7T.long <- SGmyelin.electrodes.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") #long formatted df for grouping
SGmyelin.electrodes.7T <- SGmyelin.electrodes.7T.long %>% group_by(subses, region) %>% #mean R1 in depths 1-3 for each region
  do(superficial_R1 = mean(.$R1)) %>% 
  unnest(cols = superficial_R1) %>% 
  pivot_wider(id_cols = subses, names_from = "region", values_from = "superficial_R1")
SGmyelin.electrodes.7T <- merge(SGmyelin.electrodes.7T, participants, by = "subses")

### deep depths
IGmyelin.electrodes.7T <- do.call(rbind, myelin.electrodes.7T[4:7]) #merge data for bottom 4 depths
IGmyelin.electrodes.7T$depth <- substr(row.names(IGmyelin.electrodes.7T), 1, 7) #assign depth
cols_to_pivot <- names(IGmyelin.electrodes.7T)[16:75] #atlas region cols
IGmyelin.electrodes.7T.long <- IGmyelin.electrodes.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") 
IGmyelin.electrodes.7T <- IGmyelin.electrodes.7T.long %>% group_by(subses, region) %>%
  do(deep_R1 = mean(.$R1)) %>% 
  unnest(cols = deep_R1) %>% 
  pivot_wider(id_cols = subses, names_from = "region", values_from = "deep_R1")
IGmyelin.electrodes.7T <- merge(IGmyelin.electrodes.7T, participants, by = "subses")

SGIGmyelin.electrodes.7T <- list(SGmyelin.electrodes.7T, IGmyelin.electrodes.7T)
names(SGIGmyelin.electrodes.7T) <- list("superficial", "deep")
saveRDS(SGIGmyelin.electrodes.7T, "/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/SGIGR1_electrodeatlas_finalsample.RDS")

