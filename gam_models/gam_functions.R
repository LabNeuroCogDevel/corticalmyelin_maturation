library(tidyr)
library(mgcv)
library(gratia)
library(tidyverse)
library(dplyr)

#### FIT A GENERALIZED ADDITIVE (MIXED) MODEL with mgcv::gam 
##Function to fit a GAM with one smooth plus optional id-based random effect terms and save out statistics, temporal characteristics, fitted values, zero-centered smooths, and derivatives
#'@param input.df: df with variables for modeling
#'@param region: name of the input.df column to use as the dependent variable in the gam
#'@param smooth_var: name of the input.df column to fit a smooth function to 
#'@param id_var: name of the input.df column to use as the random effects variable
#'@param covariates: linear covariates to include in the gam model, can be set to "NA" if none
#'@param random_intercepts: TRUE/FALSE as to whether the gam should include random intercepts for the id_var
#'@param random_slopes: TRUE/FALSE as to whether the gam should include random slops for the id_var
#'@param knots: value of k to use for the smooth_var s() term
#'@param set_fx: TRUE/FALSE as to whether to used fixed (T) or penalized (F) splines for the smooth_var s() term  
gam.statistics.smooths <- function(input.df, region, smooth_var, id_var, covariates, random_intercepts = FALSE, random_slopes = FALSE, knots, set_fx = FALSE){
  
  ## MODEL FITTING ##
  
  #Format input data
  gam.data <- input.df #df for gam modeling
  parcel <- region 
  region <- str_replace(region, "-", "_") #region for gam modeling
  gam.data[,id_var] <- as.factor(gam.data[,id_var]) #random effects variable must be a factor for mgcv::gam
  if(covariates != "NA"){
    covs <- str_split(covariates, pattern = "\\+", simplify = T)
    for(cov in covs){
     cov <- gsub(" ", "", cov)
     if(class(gam.data[,cov]) == "character"){
       gam.data[,cov] <- as.factor(gam.data[,cov]) #format covariates as factors if needed
      }
  }}
  
  #Fit the model
  if(random_intercepts == FALSE && random_slopes == FALSE){
    if(covariates != "NA"){
      modelformula <- as.formula(sprintf("%s ~ s(%s, k = %s, fx = %s) + %s", region, smooth_var, knots, set_fx, covariates))
      gam.model <- gam(modelformula, method = "REML", data = gam.data)
      gam.results <- summary(gam.model)}
    if(covariates == "NA"){
      modelformula <- as.formula(sprintf("%s ~ s(%s, k = %s, fx = %s)", region, smooth_var, knots, set_fx))
      gam.model <- gam(modelformula, method = "REML", data = gam.data)
      gam.results <- summary(gam.model)}
  }
  
  if(random_intercepts == TRUE){
    if(covariates != "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%5$s, bs = 're') + %6$s", region, smooth_var, knots, set_fx, id_var, covariates))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
    if(covariates == "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%5$s, bs = 're')", region, smooth_var, knots, set_fx, id_var))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
  }
  
  if(random_slopes == TRUE){
    if(covariates != "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%5$s, bs = 're') + s(%5$s, %2$s, bs = 're') + %6$s", region, smooth_var, knots, set_fx, id_var, covariates))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
    if(covariates == "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%5$s, bs = 're') + s(%5$s, %2$s, bs = 're')", region, smooth_var, knots, set_fx, id_var))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
  }
  
  ## PREDICTION DATA ## 
  
  #Extract gam input data
  df <- as.data.frame(unclass(gam.model$model), stringsAsFactors = TRUE)  #extract the data used to build the gam, i.e., a df of y + predictor values 

  #Create a prediction data frame
  np <- 200 #predict at np increments of smooth_var
  thisPred <- data.frame(init = rep(0,np)) #initiate a prediction df 
  
  theseVars <- attr(gam.model$terms,"term.labels") #gam model predictors 
  varClasses <- attr(gam.model$terms,"dataClasses") #classes of the model predictors and y measure
  thisResp <- as.character(gam.model$terms[[2]]) #the measure to predict
  for (v in c(1:length(theseVars))) { #fill the prediction df with data for predictions. These data will be used to predict the output measure (y) at np increments of the smooth_var, holding other model terms constant
    thisVar <- theseVars[[v]]
    thisClass <- varClasses[thisVar]
    if (thisVar == smooth_var) { 
      thisPred[,smooth_var] = seq(min(df[,smooth_var],na.rm = T),max(df[,smooth_var],na.rm = T), length.out = np) #generate a range of np data points, from minimum of smooth term to maximum of smooth term
    } else {
      switch (thisClass,
              "numeric" = {thisPred[,thisVar] = median(df[,thisVar])}, #make predictions based on median value
              "character" = {thisPred[,thisVar] = levels(df[,thisVar])[[1]]}, #make predictions based on first level of char
              "factor" = {thisPred[,thisVar] = levels(df[,thisVar])[[1]]}, #make predictions based on first level of factor 
              "ordered" = {thisPred[,thisVar] = levels(df[,thisVar])[[1]]} #make predictions based on first level of ordinal variable
      )
    }
  }
  pred <- thisPred %>% select(-init)
  
  ## MODEL STATISTICS ##
  
  #GAM derivatives
  #Get derivatives of the smooth function using finite differences
  derv <- derivatives(gam.model, term = sprintf('s(%s)',smooth_var), data = pred, interval = "simultaneous", unconditional = F) #derivative at 200 indices of smooth_var with a simultaneous CI
  #Identify derivative significance window(s)
  derv <- derv %>% #add "sig" column (TRUE/FALSE) to derv
    mutate(sig = !(0 > lower & 0 < upper)) #derivative is sig if the lower CI is not < 0 while the upper CI is > 0 (i.e., when the CI does not include 0)
  derv$sig_deriv = derv$derivative*derv$sig #add "sig_deriv derivatives column where non-significant derivatives are set to 0
  mean.derivative <- mean(derv$derivative)
  
  #Model summary outputs
  #Signed F value for the smooth term and GAM-based significance of the smooth term
  gam.smooth.F <- gam.results$s.table[1,3] #first row is s(smooth_var), third entry is F
  if(mean.derivative < 0){ #if the average derivative is less than 0, make the effect size estimate negative
    gam.smooth.F <- gam.smooth.F*-1}
  
  gam.smooth.pvalue <- gam.results$s.table[1,4] #first row is s(smooth_var), fourth entry is p-value

  #Derivative-based temporal characteristics
  #Age of developmental change onset
  if(sum(derv$sig) > 0){ #if derivative is significant at at least 1 age
    change.onset <- min(derv$data[derv$sig==T])} #find first age in the smooth where derivative is significant
  if(sum(derv$sig) == 0){ #if gam derivative is never significant
    change.onset <- NA} #assign NA
  
  #Age of maximal developmental change
  if(sum(derv$sig) > 0){ 
    derv$abs_sig_deriv = round(abs(derv$sig_deriv),5) #absolute value significant derivatives
    maxval <- max(derv$abs_sig_deriv) #find the largest derivative
    window.peak.change <- derv$data[derv$abs_sig_deriv == maxval] #identify the age(s) at which the derivative is greatest in absolute magnitude
    peak.change <- mean(window.peak.change)} #identify the age of peak developmental change
  if(sum(derv$sig) == 0){ 
    peak.change <- NA}  
  
  #Age of decrease onset
  if(sum(derv$sig) > 0){ 
    decreasing.range <- derv$data[derv$sig_deriv < 0] #identify all ages with a significant negative derivative (i.e., smooth_var indices where y is decreasing)
    if(length(decreasing.range) > 0)
      decrease.onset <- min(decreasing.range) #find youngest age with a significant negative derivative
    if(length(decreasing.range) == 0)
      decrease.onset <- NA}
  if(sum(derv$sig) == 0){
    decrease.onset <- NA}  
  
  #Age of decrease offset
  if(sum(derv$sig) > 0){ 
    decreasing.range <- derv$data[derv$sig_deriv < 0] #identify all ages with a significant negative derivative (i.e., smooth_var indices where y is decreasing)
    if(length(decreasing.range) > 0){
      last.decrease <- max(decreasing.range) #find oldest age with a significant negative derivative
      if(last.decrease == derv$data[length(derv$data)]) #if the last age of significant decrease is the oldest in the dataset
        decrease.offset <- last.decrease
      if(last.decrease != derv$data[length(derv$data)]){ 
        decrease.offset.row <- which(derv$data == last.decrease) + 1 #use above to find the first age when the derivative is not significant
        decrease.offset <- derv$data[decrease.offset.row]}
    }
    if(length(decreasing.range) == 0)
      decrease.offset <- NA}
  if(sum(derv$sig) == 0){ 
    decrease.offset <- NA}  
  
  #Age of increase onset
  if(sum(derv$sig) > 0){ 
    increasing.range <- derv$data[derv$sig_deriv > 0] #identify all ages with a significant positive derivative (i.e., smooth_var indices where y is increasing)
    if(length(increasing.range) > 0)
      increase.onset <- min(increasing.range) #find oldest age with a significant positive derivative
    if(length(increasing.range) == 0)
      increase.onset <- NA}
  if(sum(derv$sig) == 0){ 
    increase.onset <- NA}  
  
  #Age of increase offset
  if(sum(derv$sig) > 0){ 
    increasing.range <- derv$data[derv$sig_deriv > 0] #identify all ages with a significant positive derivative (i.e., smooth_var indices where y is increasing)
    if(length(increasing.range) > 0){
      last.increase <- max(increasing.range) #find oldest age with a significant positive derivative
      if(last.increase == derv$data[length(derv$data)]) #if the last age of significant increase is the oldest in the dataset
        increase.offset <- last.increase
      if(last.increase != derv$data[length(derv$data)]){ 
        increase.offset.row <- which(derv$data == last.increase) + 1 #use above to find the first age when the derivative is not significant
        increase.offset <- derv$data[increase.offset.row]}
    }
    if(length(increasing.range) == 0)
      increase.offset <- NA}
  if(sum(derv$sig) == 0){ 
    increase.offset <- NA}  
  
  #Age of last change
  if(sum(derv$sig) > 0){ 
    change.offset <- max(derv$data[derv$sig==T])} #find last age in the smooth where derivative is significant
  if(sum(derv$sig) == 0){ 
    change.offset <- NA}  
  
  gam.statistics <- data.frame(region = as.character(parcel), GAM.smooth.Fvalue = as.numeric(gam.smooth.F), GAM.smooth.pvalue = as.numeric(gam.smooth.pvalue), 
                                   smooth.change.onset = as.numeric(change.onset), smooth.peak.change = as.numeric(peak.change), smooth.decrease.onset = as.numeric(decrease.onset), 
                                   smooth.decrease.offset = as.numeric(decrease.offset), smooth.increase.onset = as.numeric(increase.onset), 
                                   smooth.increase.offset = as.numeric(increase.offset), smooth.last.change = as.numeric(change.offset))
 
  
  ## MODEL FITTED VALUES ##
  
  #Generate predictions (fitted values) based on the gam model and predication data frame
  gam.fittedvalues <- fitted_values(object = gam.model, data = pred)
  gam.fittedvalues <- gam.fittedvalues %>% select(all_of(smooth_var), fitted, se, lower, upper)
  gam.fittedvalues$region <- parcel
  
  ## MODEL SMOOTH ESTIMATES ## 
  
  #Estimate the zero-averaged gam smooth function 
  gam.smoothestimates <- smooth_estimates(object = gam.model, data = pred, smooth = sprintf('s(%s)',smooth_var))
  gam.smoothestimates <- gam.smoothestimates %>% select(age, est, se)
  gam.smoothestimates$region <- parcel
  
  ## MODEL DERIVATIVES ## 
  
  #Format derv dataframe to output
  gam.derivatives <- derv %>% select(data, derivative, lower, upper, sig, sig_deriv)
  names(gam.derivatives) <- c(sprintf("%s", smooth_var), "derivative", "lower", "upper", "significant", "significant.derivative")
  gam.derivatives$region <- parcel
  
  gam.results <- list(gam.statistics, gam.fittedvalues, gam.smoothestimates, gam.derivatives)
  names(gam.results) <- list("gam.statistics", "gam.fittedvalues", "gam.smoothestimates", "gam.derivatives")
  return(gam.results)
}


#### FIT A GENERALIZED ADDITIVE (MIXED) MODEL WITH A FACTOR-SMOOTH INTERACTION
##Function to fit a GAM with one smooth plus optional id-based random effect terms as well as a factor-smooth interaction of interest
#'@param input.df: df with variables for modeling
#'@param region: name of the input.df column to use as the dependent variable in the gam
#'@param smooth_var: name of the input.df column to fit a smooth function to 
#'@param id_var: name of the input.df column to use as the random effects variable
#'@param int_var: name of the input.df column to use as the factor in an interaction. Consider whether you want this to be an ordered factor!
#'@param covariates: linear covariates to include in the gam model, can be set to "NA" if none
#'@param random_intercepts: TRUE/FALSE as to whether the gam should include random intercepts for the id_var
#'@param random_slopes: TRUE/FALSE as to whether the gam should include random slops for the id_var
#'@param knots: value of k to use for the smooth_var s() term
#'@param set_fx: TRUE/FALSE as to whether to used fixed (T) or penalized (F) splines for the smooth_var s() term  
gam.factorsmooth.interaction <- function(input.df, region, smooth_var, id_var, int_var, covariates, random_intercepts = FALSE, random_slopes = FALSE, knots, set_fx = FALSE){
  
  ## MODEL FITTING ##
  
  #Format input data
  gam.data <- input.df #df for gam modeling
  parcel <- region 
  region <- str_replace(region, "-", "_") #region for gam modeling
  gam.data[,id_var] <- as.factor(gam.data[,id_var]) #random effects variable must be a factor for mgcv::gam
  if(covariates != "NA"){
    covs <- str_split(covariates, pattern = "\\+", simplify = T)
    for(cov in covs){
      cov <- gsub(" ", "", cov)
      if(class(gam.data[,cov]) == "character"){
        gam.data[,cov] <- as.factor(gam.data[,cov]) #format covariates as factors if needed
      }
    }}
  
  #Fit the model
  if(random_intercepts == FALSE && random_slopes == FALSE){
    if(covariates != "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%2$s, by = %5$s, k = %3$s, fx = %4$s) + %6$s", region, smooth_var, knots, set_fx, int_var, covariates))
      gam.model <- gam(modelformula, method = "REML", data = gam.data)
      gam.results <- summary(gam.model)}
    if(covariates == "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%2$s, by = %5$s, k = %3$s, fx = %4$s)", region, smooth_var, knots, set_fx, int_var))
      gam.model <- gam(modelformula, method = "REML", data = gam.data)
      gam.results <- summary(gam.model)}
  }
  
  if(random_intercepts == TRUE){
    if(covariates != "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%2$s, by = %5$s, k = %3$s, fx = %4$s) + s(%6$s, bs = 're') + %7$s", region, smooth_var, knots, set_fx, int_var, id_var, covariates))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
    if(covariates == "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%2$s, by = %5$s, k = %3$s, fx = %4$s) + s(%6$s, bs = 're')", region, smooth_var, knots, set_fx, int_var, id_var))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
  }
  
  if(random_slopes == TRUE){
    if(covariates != "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%2$s, by = %5$s, k = %3$s, fx = %4$s) +s(%6$s, bs = 're') + s(%6$s, %2$s, bs = 're') + %7$s", region, smooth_var, knots, set_fx, int_var, id_var, covariates))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
    if(covariates == "NA"){
      modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%2$s, by = %5$s, k = %3$s, fx = %4$s) +s(%6$s, bs = 're') + s(%6$s, %2$s, bs = 're')", region, smooth_var, knots, set_fx, int_var, id_var))
      gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
      gam.results <- summary(gam.model)}
  }
  
  ## EXTRACT INTERACTION STATISTICS ##
  
  #F value for the interaction term and GAM-based significance of the term
  gam.int.F <- gam.results$s.table[2,3] #row 1: s(smooth_var), row 2: s(smooth_var):int_var, row 3: s(id_var)
  gam.int.pvalue <- gam.results$s.table[2,4]
  
  interaction.stats <- data.frame(as.character(parcel), as.numeric(gam.int.F), as.numeric(gam.int.pvalue))
  colnames(interaction.stats) <- c("tract", "GAM.int.Fvalue", "GAM.int.pvalue")
  return(interaction.stats)
}

#### FIT A GENERALIZED ADDITIVE (MIXED) MODEL WITH A LINEAR COVARIATE OF INTEREST
##Function to fit a GAM with one smooth plus optional id-based random effect terms and a linear main effect for a covariate of interest, and save out statistics
gam.linearcovariate.maineffect <- function(input.df, region, smooth_var, id_var, covariates, random_intercepts = FALSE, random_slopes = FALSE, knots, set_fx = FALSE){
  
  ## MODEL FITTING ##
  
  #Format input data
  gam.data <- input.df #df for gam modeling
  parcel <- region 
  region <- str_replace(region, "-", "_") #region for gam modeling
  gam.data[,id_var] <- as.factor(gam.data[,id_var]) #random effects variable must be a factor for mgcv::gam

  #Fit the model
  if(random_intercepts == FALSE && random_slopes == FALSE){
    modelformula <- as.formula(sprintf("%s ~ s(%s, k = %s, fx = %s) + %s", region, smooth_var, knots, set_fx, covariates))
    gam.model <- gam(modelformula, method = "REML", data = gam.data)
    gam.results <- summary(gam.model)
  }
  
  if(random_intercepts == TRUE){
    modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%5$s, bs = 're') + %6$s", region, smooth_var, knots, set_fx, id_var, covariates))
    gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
    gam.results <- summary(gam.model)
  }
  if(random_slopes == TRUE){
    modelformula <- as.formula(sprintf("%1$s ~ s(%2$s, k = %3$s, fx = %4$s) + s(%5$s, bs = 're') + s(%5$s, %2$s, bs = 're') + %6$s", region, smooth_var, knots, set_fx, id_var, covariates))
    gam.model <- gam(modelformula, method = "REML", family = gaussian(link = "identity"), data = gam.data)
    gam.results <- summary(gam.model)
  }
  
  #GAM statistics
  #t-value for the covariate of interest term and GAM-based significance of this term
  gam.cov.tvalue <- gam.results$p.table[2,3]
  #GAM based significance of the term
  gam.cov.pvalue <- gam.results$p.table[2,4]
  
  gam.results <- data.frame(region = as.character(parcel), GAM.maineffect.tvalue = as.numeric(gam.cov.tvalue), GAM.maineffect.pvalue = as.numeric(gam.cov.pvalue))
  return(gam.results)
}
  
  
