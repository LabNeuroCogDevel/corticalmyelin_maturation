#A script to organize and clean measures of Brodmann area EEG aperiodic activity for R1-EEG analyses
library(dplyr)
library(tidyverse)
source("/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/surface_metrics/surface_measures/extract_surfacestats.R")

############################################################################################################
#### Read in Data ####

# Read in final participant list 
participants <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MP2RAGE_finalsample_demographics.csv")
participants <- participants %>% mutate(subses = sprintf("%s_%s", subject_id, session_id)) #create a unique scan identifier 

# Read in aperiodic offset and exponent 
EEG.fooof <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/EEG/allSubjectsAllChannelsFooofMeasures_20230911.csv") %>%
  select(Subject, Channel, Offset, Exponent, Condition) %>% filter(Condition == "eyesOpen") #291 unique visits
EEG.fooof$Subject <- gsub("11665", "11390", EEG.fooof$Subject) #update subject id to match MRI
EEG.fooof$Subject <- gsub("11748", "11515", EEG.fooof$Subject) #update subject id to match MRI
EEG.fooof$lunaid <- as.integer(sub("\\_.*", "", EEG.fooof$Subject)) #create lunaid from the Subject variable
EEG.fooof$eeg.date <- as.integer(gsub(".*?_", "", EEG.fooof$Subject)) #create eeg date identifier from the Subject variable

# Read in FIT data
EEG.fit <-  read.csv("/Volumes/Hera/Projects/corticalmyelin_development/EEG/allSubjectsErrorMeasures_20230516.csv") %>%
  select(Subject, Channel, Error, R.Squared, Condition) %>% filter(Condition == "eyesOpen")
EEG.fit$Subject <- gsub("11665", "11390", EEG.fit$Subject) #update subject id to match MRI
EEG.fit$Subject <- gsub("11748", "11515", EEG.fit$Subject) #update subject id to match MRI
EEG.fit$lunaid <- as.integer(sub("\\_.*", "", EEG.fit$Subject))
EEG.fit$eeg.date <- as.integer(gsub(".*?_", "", EEG.fit$Subject))

EEG.fooof <- left_join(EEG.fooof, EEG.fit, by = c("Subject", "Channel", "Condition", "lunaid", "eeg.date"))

############################################################################################################
#### Clean FOOOF data ####

# Exclude electrodes with high spectral fit errors and low R2 (< 1% of electrodes)
EEG.fooof$Exponent[!is.na(EEG.fooof$Error) & EEG.fooof$Error > 0.1] <- NA #mean error = 0.042484
EEG.fooof$Offset[!is.na(EEG.fooof$Error) & EEG.fooof$Error > 0.1] <- NA 

EEG.fooof$Exponent[!is.na(EEG.fooof$R.Squared) & EEG.fooof$R.Squared < 0.5] <- NA #mean Rsq = 0.9830115
EEG.fooof$Offset[!is.na(EEG.fooof$R.Squared) & EEG.fooof$R.Squared < 0.5] <- NA 

# Exclude electrodes at the participant level that have data +- 2 SDs from the measure mean
exponent.EEGatlas.7T <- EEG.fooof %>%  pivot_wider(id_cols = c("lunaid", "eeg.date"), names_from = "Channel", values_from = "Exponent")
names(exponent.EEGatlas.7T)[3:66] <- sprintf("%s_exponent", names(exponent.EEGatlas.7T)[3:66]) 

offset.EEGatlas.7T <- EEG.fooof %>%  pivot_wider(id_cols = c("lunaid", "eeg.date"), names_from = "Channel", values_from = "Offset")
names(offset.EEGatlas.7T)[3:66] <- sprintf("%s_offset", names(offset.EEGatlas.7T)[3:66]) 

###outlier replacement function
identify_and_replace_outliers <- function(df, measure) {
  
  # Identify columns with measure in their name
  measure_cols <- grep(measure, names(df))
  
  # Iterate over rows and identify outliers in these columns
  for (i in 1:nrow(df)) {
    # Extract values for the current row
    row_values <- as.numeric(unlist(df[i, measure_cols]))
    
    # Calculate mean and standard deviation of the offset columns in the row
    row_mean <- mean(row_values, na.rm = T)
    row_sd <- sd(row_values, na.rm = T)
    
    # Identify values that are +- 2 standard deviations away from the mean
    row_outliers <- row_values > (row_mean + (2 * row_sd)) | row_values < (row_mean - (2 * row_sd))
    
    # Replace outliers with NA in the original dataframe
    df[i, measure_cols] <- ifelse(row_outliers, NA, df[i, measure_cols])
  }
  
  return(df)
}

exponent.EEGatlas.7T <- identify_and_replace_outliers(exponent.EEGatlas.7T, measure = "exponent")
offset.EEGatlas.7T <- identify_and_replace_outliers(offset.EEGatlas.7T, measure = "offset")

# Exclude timepoints at the group level with values that are +- 4 SD from the group mean
allchannels.meanexponent <- EEG.fooof %>% group_by(Subject) %>% do(mean.exponent = mean(.$Exponent, na.rm = TRUE)) %>% unnest(cols = c("mean.exponent"))
exponent.mean <- mean(allchannels.meanexponent$mean.exponent)
exponent.sd <- sd(allchannels.meanexponent$mean.exponent)
lowerbound <- exponent.mean-(4*exponent.sd) 
upperbound <- exponent.mean+(4*exponent.sd)
exclude.id.exponent <- allchannels.meanexponent %>% filter(mean.exponent < lowerbound) %>% select(Subject) 
exponent.EEGatlas.7T <- exponent.EEGatlas.7T[!(exponent.EEGatlas.7T$lunaid == strsplit(exclude.id.exponent$Subject, "_")[[1]][1] & exponent.EEGatlas.7T$eeg.date == strsplit(exclude.id.exponent$Subject, "_")[[1]][2]),]

allchannels.meanoffset <- EEG.fooof %>% group_by(Subject) %>% do(mean.offset = mean(.$Offset, na.rm = TRUE)) %>% unnest(cols = c("mean.offset"))
offset.mean <- mean(allchannels.meanoffset$mean.offset)
offset.sd <- sd(allchannels.meanoffset$mean.offset)
lowerbound <- 0
upperbound <- offset.mean+(4*offset.sd)
exclude.ids.offset <- allchannels.meanoffset %>% filter(mean.offset < lowerbound) %>% select(Subject)
offset.EEGatlas.7T <- offset.EEGatlas.7T[!(offset.EEGatlas.7T$lunaid == strsplit(exclude.ids.offset$Subject[1], "_")[[1]][1] & offset.EEGatlas.7T$eeg.date == strsplit(exclude.ids.offset$Subject[1], "_")[[1]][2]),]
offset.EEGatlas.7T <- offset.EEGatlas.7T[!(offset.EEGatlas.7T$lunaid == strsplit(exclude.ids.offset$Subject[2], "_")[[1]][1] & offset.EEGatlas.7T$eeg.date == strsplit(exclude.ids.offset$Subject[2], "_")[[1]][2]),]
offset.EEGatlas.7T <- offset.EEGatlas.7T[!(offset.EEGatlas.7T$lunaid == strsplit(exclude.ids.offset$Subject[3], "_")[[1]][1] & offset.EEGatlas.7T$eeg.date == strsplit(exclude.ids.offset$Subject[3], "_")[[1]][2]),]
exclude.id.offset <- allchannels.meanoffset %>% filter(mean.offset > upperbound) %>% select(Subject)
offset.EEGatlas.7T <- offset.EEGatlas.7T[!(offset.EEGatlas.7T$lunaid == strsplit(exclude.id.offset$Subject, "_")[[1]][1] & offset.EEGatlas.7T$eeg.date == strsplit(exclude.id.offset$Subject, "_")[[1]][2]),]

############################################################################################################
#### Combine frontal electrode data across brodmann areas ####

# Average fooof measures across electrodes
combine_electrodes <- function(df, electrode_list, output_name){
  df[output_name] <- df %>% select(all_of(electrode_list)) %>% rowMeans(na.rm = T)
  return(df)
}

exponent.EEGatlas.7T <- combine_electrodes(df = exponent.EEGatlas.7T, electrode_list = c("F7_exponent", "F8_exponent"), output_name = "Brodmann.45_exponent")
exponent.EEGatlas.7T <- combine_electrodes(df = exponent.EEGatlas.7T, electrode_list = c("F3_exponent", "F4_exponent", "F5_exponent", "F6_exponent"), output_name = "Brodmann.9_exponent")
exponent.EEGatlas.7T <- combine_electrodes(df = exponent.EEGatlas.7T, electrode_list = c("F1_exponent", "F2_exponent"), output_name = "Brodmann.8_exponent")
exponent.EEGatlas.7T <- combine_electrodes(df = exponent.EEGatlas.7T, electrode_list = c("FC1_exponent", "FC2_exponent", "FC3_exponent", "FC4_exponent", "FC5_exponent", "FC6_exponent", "C1_exponent", "C2_exponent"), output_name = "Brodmann.4.6_exponent")

offset.EEGatlas.7T <- combine_electrodes(df = offset.EEGatlas.7T, electrode_list = c("F7_offset", "F8_offset"), output_name = "Brodmann.45_offset")
offset.EEGatlas.7T <- combine_electrodes(df = offset.EEGatlas.7T, electrode_list = c("F3_offset", "F4_offset", "F5_offset", "F6_offset"), output_name = "Brodmann.9_offset")
offset.EEGatlas.7T <- combine_electrodes(df = offset.EEGatlas.7T, electrode_list = c("F1_offset", "F2_offset"), output_name = "Brodmann.8_offset")
offset.EEGatlas.7T <- combine_electrodes(df = offset.EEGatlas.7T, electrode_list = c("FC1_offset", "FC2_offset", "FC3_offset", "FC4_offset", "FC5_offset", "FC6_offset", "C1_offset", "C2_offset"), output_name = "Brodmann.4.6_offset")

fooof.brodmann.7T <- left_join(exponent.EEGatlas.7T, offset.EEGatlas.7T, by = c("lunaid", "eeg.date"))

############################################################################################################
#### Combine with EEG electrode R1 measures for statistical analysis ####

# Superficial and deep cortex R1 in Brodmann areas
mean.myelin.measures <- list("Mean_R1map.0.8%","Mean_R1map.0.7%","Mean_R1map.0.6%","Mean_R1map.0.5%","Mean_R1map.0.4%","Mean_R1map.0.3%","Mean_R1map.0.2%") #measures to extract data for 
myelin.brodmann.7T <- lapply(mean.myelin.measures, function(x) {
  extract_surfacestats("PALS_B12_Brodmann", x)})
names(myelin.brodmann.7T) <- list("depth_1", "depth_2", "depth_3", "depth_4", "depth_5", "depth_6", "depth_7")

### superficial depths
SGmyelin.brodmann.7T <- do.call(rbind, myelin.brodmann.7T[1:3]) 
SGmyelin.brodmann.7T$depth <- substr(row.names(SGmyelin.brodmann.7T), 1, 7) #assign depth
cols_to_pivot <- names(SGmyelin.brodmann.7T)[15:56][!grepl("MEDIAL.WALL", names(SGmyelin.brodmann.7T)[15:56])] #brodmann region cols
SGmyelin.brodmann.7T.long <- SGmyelin.brodmann.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") 
SGmyelin.brodmann.7T <- SGmyelin.brodmann.7T.long %>% group_by(subject_id,  session_id, region) %>% 
  do(superficial_R1 = mean(.$R1)) %>% 
  unnest(cols = superficial_R1) %>% 
  pivot_wider(id_cols = c("subject_id", "session_id"), names_from = "region", values_from = "superficial_R1")
SGmyelin.brodmann.7T <- merge(SGmyelin.brodmann.7T, participants, by = c("subject_id", "session_id"))

### deep depths
IGmyelin.brodmann.7T <- do.call(rbind, myelin.brodmann.7T[4:7]) 
IGmyelin.brodmann.7T$depth <- substr(row.names(IGmyelin.brodmann.7T), 1, 7) #assign depth
cols_to_pivot <- names(IGmyelin.brodmann.7T)[15:56][!grepl("MEDIAL.WALL", names(IGmyelin.brodmann.7T)[15:56])] #brodmann region cols
IGmyelin.brodmann.7T.long <- IGmyelin.brodmann.7T %>% pivot_longer(cols = all_of(cols_to_pivot), names_to = "region", values_to = "R1") 
IGmyelin.brodmann.7T <- IGmyelin.brodmann.7T.long %>% group_by(subject_id,  session_id, region) %>% 
  do(deep_R1 = mean(.$R1)) %>% 
  unnest(cols = deep_R1) %>% 
  pivot_wider(id_cols = c("subject_id", "session_id"), names_from = "region", values_from = "deep_R1")
IGmyelin.brodmann.7T <- merge(IGmyelin.brodmann.7T, participants, by = c("subject_id", "session_id"))

SGIGmyelin.brodmann.7T <- list(SGmyelin.brodmann.7T, IGmyelin.brodmann.7T)
names(SGIGmyelin.brodmann.7T) <- list("superficial", "deep")

SGIGmyelin.brodmann.7T <- lapply(SGIGmyelin.brodmann.7T, function(depth){
  names(depth) <- gsub("Brodmann.45", "Brodmann.45_R1", names(depth))
  names(depth) <- gsub("Brodmann.9", "Brodmann.9_R1", names(depth))
  names(depth) <- gsub("Brodmann.8", "Brodmann.8_R1", names(depth))
  depth$Brodmann.4.6_R1 <- depth %>% select(Brodmann.4, Brodmann.6) %>% rowMeans()
  return(depth)
})

myelin.brodmann.7T <- lapply(SGIGmyelin.brodmann.7T, function(depth){
  depth <- left_join(depth, fooof.brodmann.7T, by = c("lunaid", "eeg.date"))
  return(depth)
})
saveRDS(myelin.brodmann.7T, "/Volumes/Hera/Projects/corticalmyelin_development/EEG/R1_aperiodicactivity_brodmann.RDS")


