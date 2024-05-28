library(arrow)
library(dplyr)
library(tidyr)

#atlas can be one of: aparc, glasser, gordon333dil, Juelich, Schaefer2018_400Parcels_17Networks_order, Schaefer2018_200Parcels_17Networks_order
#measure can be one of: NumVert, SurfArea, GrayVol, ThickAvg, ThickStd, MeanCurv, GausCurv, FoldInd, CurvInd, Mean_w-g.pct, Mean_R1map.0.x%, StdDev_R1map_0.x%, Min_R1map.0.x%, Max_R1map.0.x%, Range_R1map.0.x%, SNR_R1map.0.x%

extract_surfacestats <- function(myatlas, mymeasure){
  #final study sample for 7T structural data
  participants <- read.csv("/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_MP2RAGE_finalsample_demographics.csv")
  
  #surface anatomical and myelin measures parquet
  surfacemeasures <- read_parquet("/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/7T_BrainMechanisms_surfacestats_allatlases.parquet")
  
  #get data for my atlas of interest and format atlas labels to be hemisphere-specific if needed
  atlasmeasures <- surfacemeasures %>% filter(atlas == myatlas)
  if(myatlas == "aparc"){
    atlasmeasures$StructName <- paste0(sprintf("%s_", atlasmeasures$hemisphere), atlasmeasures$StructName)
  }
  if(myatlas == "MRSIatlas"){
    replace_bilateral <- function(struct_name, hemisphere) { #add hemisphere information to Bilateral ROIs
      ifelse(hemisphere == "lh", 
             gsub("Bilateral-", "Left-", struct_name), 
             ifelse(hemisphere == "rh", 
                    gsub("Bilateral-", "Right-", struct_name), 
                    struct_name))}
    atlasmeasures <- atlasmeasures %>% mutate(StructName = replace_bilateral(StructName, hemisphere))
  }
    
  #get data for my measure of interest
  measure.df <- atlasmeasures %>% select(subject_id, session_id, StructName, all_of(mymeasure))
  measure.df <- measure.df %>% filter(StructName != "???" & StructName != "Background+FreeSurfer_Defined_Medial_Wall") #remove unknown/medial wall label
  measure.df <- measure.df %>% pivot_wider(names_from = "StructName", values_from = all_of(mymeasure), values_fn = mean) #long to wide df
  
  #get data for just the final study sample
  measure.df <- merge(participants, measure.df, by = c("subject_id", "session_id"), sort = F)
}
