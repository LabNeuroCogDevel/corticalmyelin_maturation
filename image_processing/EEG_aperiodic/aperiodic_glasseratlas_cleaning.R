#A script to organize and clean measures of regional EEG aperiodic activity for R1-EEG analyses
library(dplyr)
library(tidyverse)

############################################################################################################
#### Read in Data ####
setwd("/Users/valeriesydnor/Documents/Image_Processing/corticalmyelin_development/")

# Read in final participant list 
participants <- read.csv("./sample_info/7T_MP2RAGE_finalsample_demographics.csv")
participants <- participants %>% mutate(subses = sprintf("%s_%s", sub("^sub-", "", subject_id), sub("^ses-", "", session_id)))

# Read in aperiodic measures in glasser regions
EEG.exponent <- read.csv("./EEG/FOOOF_aperiodic_glasser.csv") %>% select(Subject, channel, exponent) %>%
                mutate(channel = paste0(substr(channel, 1, nchar(channel) - 2), "_exponent"))
colnames(EEG.exponent)[1] <- "subses"
EEG.exponent <- EEG.exponent %>% pivot_wider(id_cols = subses, names_from = channel, values_from = exponent)
EEG.exponent$subses <- gsub("11665", "11390", EEG.exponent$subses) #update subject id to match MRI
EEG.exponent$subses <- gsub("11748", "11515", EEG.exponent$subses) #update subject id to match MRI

EEG.exponent <- EEG.exponent[EEG.exponent$subses %in% participants$subses,] #data for R1 sample; N = 199 EEGs

############################################################################################################
#### Exclude poor quality EEG scans (abnormal signal or source localization) ####

# Exclude EEG scans where the spatial distribution of the aperiodic exponent in the frontal lobe is anti-correlated with the group map
###compute group mean frontal cortex map
frontal.exponent.sample <- EEG.exponent %>% select(contains("exponent")) %>% colMeans %>% as.data.frame() %>% set_names("exponent") %>% 
                           mutate(orig_parcelname = row.names(.))

###compute correlation of each individual's map to the group mean
EEG.exponent.long <- EEG.exponent %>% pivot_longer(cols = contains("exponent"), names_to = "orig_parcelname", values_to = "exponent")

exponent_groupmean_correlation <- function(id){
  exponent.individual <- EEG.exponent.long %>% filter(subses == id)
  colnames(exponent.individual)[3] <- "exponent.id"
  exponent.individual <- merge(exponent.individual, frontal.exponent.sample)
  corr.val <- cor(exponent.individual$exponent.id, exponent.individual$exponent)
  corr.result <- data.frame(id, corr.val)
  return(corr.result)
}

ids <- unique(EEG.exponent$subses)
corr.results <- bind_rows(lapply(ids, exponent_groupmean_correlation)) %>% as.data.frame() %>% set_names("subses", "corr")
subses.exclusions <- corr.results %>% filter(corr < 0)

EEG.exponent <- EEG.exponent[!(EEG.exponent$subses %in% subses.exclusions$subses),]

############################################################################################################
#### Save output ####

saveRDS(EEG.exponent, "./EEG/aperiodicexponent_glasseratlas_finalsample.RDS")
