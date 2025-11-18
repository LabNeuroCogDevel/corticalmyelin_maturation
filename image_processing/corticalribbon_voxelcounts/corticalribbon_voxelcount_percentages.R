#A script to calculate the number of unique voxels within the cortical ribbon between 20% and 80% of cortical thickness
library(dplyr)
library(freesurferformats)
library(purrr)

############################################################################################################
#### Cortical Ribbon Voxel Counts Function ####

ribbon_voxelcounts <- function(fsid){
  
  ## Read in Surface Data ##

  #Find surf files
  setwd(sprintf("/ocean/projects/soc230004p/shared/datasets/7TBrainMech/BIDS/derivatives/freesurfer7.4.1_long/%s/surf", fsid))
  files <- list.files(getwd(), pattern = "frontalvoxelmap")

  #Generate variable names to assign file data to 
  filenames <- c()
  for(name in files){
    Rname <- gsub('.{5}$', '', name) 
    filenames <- append(filenames, Rname) 
  }

  #Read in files and assign to variables
  for(i in 1:length(filenames)){
    Rfilename <- sprintf("%s", filenames[i]) 
    x <- read.fs.mgh(files[i]) 
    assign(Rfilename, x) 
    rm(x)
  }
  
  ## Combine lh and rh ribbon voxel information ##

  #Combine lh and rh depth data
  #$h.ribbon.voxels have voxel integers mapped to all 11 cortical depths for all vertices in left and right hemisphere of participant-specific surface
  lh.ribbon.voxels <- rbind(lh.frontalvoxelmap.0.0, lh.frontalvoxelmap.0.1, lh.frontalvoxelmap.0.2, lh.frontalvoxelmap.0.3, lh.frontalvoxelmap.0.4, lh.frontalvoxelmap.0.5, lh.frontalvoxelmap.0.6, lh.frontalvoxelmap.0.7, lh.frontalvoxelmap.0.8, lh.frontalvoxelmap.0.9, lh.frontalvoxelmap.1.00)
  rh.ribbon.voxels <- rbind(rh.frontalvoxelmap.0.0, rh.frontalvoxelmap.0.1, rh.frontalvoxelmap.0.2, rh.frontalvoxelmap.0.3, rh.frontalvoxelmap.0.4, rh.frontalvoxelmap.0.5, rh.frontalvoxelmap.0.6, rh.frontalvoxelmap.0.7, rh.frontalvoxelmap.0.8, rh.frontalvoxelmap.0.9, rh.frontalvoxelmap.1.00)

  ## Calculate unique voxels at every frontal vertex in analyzed depths ##
  
  #Exclude any vertices that fall outside of the frontal lobe, i.e., vertices where all voxel values = 0
  lh.ribbon.voxels <- lh.ribbon.voxels[, colSums(lh.ribbon.voxels != 0) > 0]
  rh.ribbon.voxels <- rh.ribbon.voxels[, colSums(rh.ribbon.voxels != 0) > 0]
  
  #Exclude top and bottom depths where <90% of signal comes from cortical gray matter
  lh.ribbon.voxels <- lh.ribbon.voxels[3:9,]
  rh.ribbon.voxels <- rh.ribbon.voxels[3:9,]

  #Calculate the number of unique voxel values present across depths at every vertex
  lh.ribbon.voxels.unique <- apply(lh.ribbon.voxels, 2, function(x) length(unique(x)))
  rh.ribbon.voxels.unique <- apply(rh.ribbon.voxels, 2, function(x) length(unique(x)))
  
  lh.ribbon.voxels.unique <- lh.ribbon.voxels.unique %>% as.data.frame() %>% set_names("voxelcount")
  rh.ribbon.voxels.unique <- rh.ribbon.voxels.unique %>% as.data.frame() %>% set_names("voxelcount")
  
  ## Calculate percent of vertices with each number of unique voxels ##

  #Percent of vertices with each unique voxel count number
  frontal.voxels.unique <- rbind(lh.ribbon.voxels.unique, rh.ribbon.voxels.unique)
 
  frontal.voxels.unique.percents <- frontal.voxels.unique %>% count(voxelcount) %>% mutate(count.percents = n/nrow(frontal.voxels.unique) *100)
  
  frontal.voxels.unique.percents$subject_id <- sub(".*(sub-[0-9]+).*", "\\1", fsid)
  frontal.voxels.unique.percents$session_id <- sub(".*(ses-[0-9]+).*", "\\1", fsid)
  
  return(frontal.voxels.unique.percents)
}

############################################################################################################
#### Apply Function to All Longitudinal Freesurfer Timepoints ####

fsid_list <- list.dirs("/ocean/projects/soc230004p/shared/datasets/7TBrainMech/BIDS/derivatives/freesurfer7.4.1_long/", recursive = FALSE, full.names = TRUE)
fsid_list <- basename(fsid_list[grepl("\\.long\\.sub", basename(fsid_list))])

ribboncounts_fullsample <- bind_rows(lapply(fsid_list, ribbon_voxelcounts))
saveRDS(ribboncounts_fullsample, "/ocean/projects/soc230004p/shared/datasets/7TBrainMech/BIDS/derivatives/ribbon_voxelcounts/ribbon_FS_voxelcounts.RDS")
