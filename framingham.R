#' ---
#' output:
#'   word_document: default
#'   html_document: default
#' ---
#' # An exploration into the framingham dataset - Can we predict heart disease?
#' 
#' ## Libraries
## ----warning=TRUE, include=FALSE---------------------------------------------------------------------------------
rm(list = ls())
libraries = c('leaps', 'tidyverse', 'bestglm','MASS', 'tree', 'dplyr', 'randomForest', 'caret','glmnet', 'bestglm', 'boot', 'GGally', 'dplyr', 'readr','boot')

for (i in libraries){
  if (!require(i, character.only = T)){
    install.packages(i)
    library(i)
  }}

#' 
#' ## Data Preparation
## ----include=FALSE-----------------------------------------------------------------------------------------------
## Import Dataset
framingham <- read.csv("framingham.csv")

## Remove N.A and Change to factor
framingham = framingham[complete.cases(framingham),]
framingham[framingham$TenYearCHD ==1,]$TenYearCHD = 'Heart Disease'
framingham[framingham$TenYearCHD == 0,]$TenYearCHD = 'No Heart Disease'
framingham['TenYearCHD'] = factor(framingham[['TenYearCHD']])

categorical = c('currentSmoker', 'diabetes', 'prevalentStroke', 'prevalentHyp','male', 'BPMeds', 'TenYearCHD')

for (i in categorical){
  framingham[i] = factor(framingham[[i]])
}

summary(framingham$TenYearCHD)

#' 
#' ## Splitting the data
## ----------------------------------------------------------------------------------------------------------------
set.seed(1)
smp_size = floor(0.80*nrow(framingham))
train_ind = sample(seq_len(nrow(framingham)), size = smp_size)
train = framingham[train_ind,]
test = framingham[-train_ind,]
x_train = train[,-16]
y_train = train$TenYearCHD

#' 
#' ## RESAMPLING METHODS
## ----------------------------------------------------------------------------------------------------------------
set.seed(1)
upsampled_train = upSample(x_train, y_train, list = FALSE, yname = "TenYearCHD")
summary(train$TenYearCHD)
summary(upsampled_train$TenYearCHD)

#' 
#' ## Subset Selection (Using Deviance to choose K best subsets, then ranking according to AIC)
## ----eval=FALSE--------------------------------------------------------------------------------------------------
## ## ON UPSAMPLED DATA
## aic.upsampled <- bestglm(Xy=upsampled_train,
##                        family=binomial,
##                        IC="AIC",
##                        method = "forward")
## ## 15 BEST AIC MODELS
## aic.upsampled.5.best <- aic.upsampled$Subsets
## plot(0:15,aic.upsampled.5.best$AIC,main="AIC-Upsampled vs No. of Variables", xlab="No. of Variables", ylab="AIC", type="b")
## 
## 
## ## ON ORIGINAL DATA
## aic.original <- bestglm(Xy=train,
##                        family=binomial,
##                        IC="AIC",
##                        method = "forward")
## ## 15 BEST AIC MODELS
## aic.original.5.best <- aic.original$Subsets
## plot(seq(0,15),aic.original.5.best$Subsets[['AIC']], main = 'AIC-Original vs No. of Variables', type = 'b', xlab = 'Number of dependent variables', ylab = 'AIC')

#' 
#' ## SUBSET SELECTION (Using Deviance to choose K best subsets, then ranking according to BIC)
## ----eval=FALSE--------------------------------------------------------------------------------------------------
## set.seed(1)
## ## ON UPSAMPLED DATA
## bic.upsampled <- bestglm(Xy=upsampled_train,
##                        family=binomial,
##                        IC="BIC",
##                        method = "forward")
## ## 15 BEST BIC MODELS
## bic.upsampled.5.best <- bic.upsampled$Subsets
## plot(0:15,bic.upsampled.5.best$BIC,main="BIC-Upsampled vs No. of Variables", xlab="No. of Variables", ylab="BIC", type="b")
## 
## ## ON ORIGINAL DATA
## bic.original <- bestglm(Xy=train,
##                        family=binomial,
##                        IC="BIC",
##                        method = "forward")
## ## 15 BEST BIC MODELS
## bic.original.5.best <- bic.original$Subsets
## bic.original.5.best
## plot(bic.original$Subsets[['BIC']][0:15], main = 'BIC-Original vs No. of Variables', type = 'b', xlab = 'Number of dependent variables', ylab = 'BIC')

#' 
#' 
#' ## CV subset selection 
## ----------------------------------------------------------------------------------------------------------------
## ON UPSAMPLED DATA
set.seed(1)
## 10-FOLD CV FOR 5 BEST AIC MODELS
aic.upsampled.5.best.m1 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentStroke+prevalentHyp+totChol+sysBP+BMI+heartRate+glucose,data=upsampled_train,family=binomial)
aic.upsampled.5.best.m2 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol+sysBP+BMI+glucose,data=upsampled_train,family=binomial)
aic.upsampled.5.best.m3 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentStroke+prevalentHyp+totChol+sysBP+diaBP+BMI+heartRate+glucose,data=upsampled_train,family=binomial)
aic.upsampled.5.best.m4 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol+sysBP+glucose,data=upsampled_train,family=binomial)
aic.upsampled.5.best.m5 <- glm(TenYearCHD~male+age+education+cigsPerDay+prevalentStroke+prevalentHyp+totChol+sysBP+BMI+heartRate+glucose,data=upsampled_train,family=binomial)

cv.err.aic.upsampled.5.best.m1 <- cv.glm(upsampled_train,aic.upsampled.5.best.m1,K=10)$delta[1]
cv.err.aic.upsampled.5.best.m2 <- cv.glm(upsampled_train,aic.upsampled.5.best.m2,K=10)$delta[1]
cv.err.aic.upsampled.5.best.m3 <- cv.glm(upsampled_train,aic.upsampled.5.best.m3,K=10)$delta[1]
cv.err.aic.upsampled.5.best.m4 <- cv.glm(upsampled_train,aic.upsampled.5.best.m4,K=10)$delta[1]
cv.err.aic.upsampled.5.best.m5 <- cv.glm(upsampled_train,aic.upsampled.5.best.m5,K=10)$delta[1]
cv.errors.aic.upsampled <- c(cv.err.aic.upsampled.5.best.m1,cv.err.aic.upsampled.5.best.m2,cv.err.aic.upsampled.5.best.m3,cv.err.aic.upsampled.5.best.m4,cv.err.aic.upsampled.5.best.m5)
plot(cv.errors.aic.upsampled,main="AIC-Upsampled CV Errors vs Variables", xlab="Model", ylab="CV Errors", type="b")
cv.errors.aic.upsampled

## 10-FOLD CV FOR 5 BEST BIC MODELS
bic.upsampled.5.best.m1 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol+sysBP+glucose,data=upsampled_train,family=binomial)
bic.upsampled.5.best.m2 <- glm(TenYearCHD~male+age+cigsPerDay+totChol+sysBP+glucose,data=upsampled_train,family=binomial)
bic.upsampled.5.best.m3 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol+sysBP+heartRate+glucose,data=upsampled_train,family=binomial)
bic.upsampled.5.best.m4 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentStroke+prevalentHyp+totChol+sysBP+heartRate+glucose,data=upsampled_train,family=binomial)
bic.upsampled.5.best.m5 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentStroke+prevalentHyp+totChol+sysBP+BMI+heartRate+glucose,data=upsampled_train,family=binomial)

cv.err.bic.upsampled.5.best.m1 <- cv.glm(upsampled_train,bic.upsampled.5.best.m1,K=10)$delta[1]
cv.err.bic.upsampled.5.best.m2 <- cv.glm(upsampled_train,bic.upsampled.5.best.m2,K=10)$delta[1]
cv.err.bic.upsampled.5.best.m3 <- cv.glm(upsampled_train,bic.upsampled.5.best.m3,K=10)$delta[1]
cv.err.bic.upsampled.5.best.m4 <- cv.glm(upsampled_train,bic.upsampled.5.best.m4,K=10)$delta[1]
cv.err.bic.upsampled.5.best.m5 <- cv.glm(upsampled_train,bic.upsampled.5.best.m5,K=10)$delta[1]
cv.errors.bic.upsampled <- c(cv.err.bic.upsampled.5.best.m1,cv.err.bic.upsampled.5.best.m2,cv.err.bic.upsampled.5.best.m3,cv.err.bic.upsampled.5.best.m4,cv.err.bic.upsampled.5.best.m5)
plot(cv.errors.bic.upsampled,main="BIC-Upsampled CV Errors vs Variables", xlab="Model", ylab="CV Errors", type="b")
cv.errors.bic.upsampled

## ON ORIGINAL DATA
## 10-FOLD CV FOR 5 BEST AIC MODELS
aic.original.5.best.m1 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentStroke+prevalentHyp+totChol+sysBP+BMI+glucose,data=train,family=binomial)
aic.original.5.best.m2 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol+sysBP+BMI+glucose,data=train,family=binomial)
aic.original.5.best.m3 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentStroke+prevalentHyp + totChol +sysBP+BMI+heartRate+glucose,data=train,family=binomial)
aic.original.5.best.m4 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol + sysBP+glucose,data=train,family=binomial)
aic.original.5.best.m5 <- glm(TenYearCHD~male+age+education+cigsPerDay+prevalentStroke+prevalentHyp + totChol +sysBP+BMI+heartRate+glucose,data=train,family=binomial)

cv.err.aic.original.5.best.m1 <- cv.glm(train,aic.original.5.best.m1,K=10)$delta[1]
cv.err.aic.original.5.best.m2 <- cv.glm(train,aic.original.5.best.m2,K=10)$delta[1]
cv.err.aic.original.5.best.m3 <- cv.glm(train,aic.original.5.best.m3,K=10)$delta[1]
cv.err.aic.original.5.best.m4 <- cv.glm(train,aic.original.5.best.m4,K=10)$delta[1]
cv.err.aic.original.5.best.m5 <- cv.glm(train,aic.original.5.best.m5,K=10)$delta[1]
cv.errors.aic.original <- c(cv.err.aic.original.5.best.m1,cv.err.aic.original.5.best.m2,cv.err.aic.original.5.best.m3,cv.err.aic.original.5.best.m4,cv.err.aic.original.5.best.m5)
plot(cv.errors.aic.original,main="AIC-Original CV Errors vs Variables", xlab="Model", ylab="CV Errors", type="b")
cv.errors.aic.original

## 10-FOLD CV FOR 5 BEST BIC MODELS
bic.original.5.best.m1 <- glm(TenYearCHD~male+age+cigsPerDay+sysBP+glucose,data=train,family=binomial)
bic.original.5.best.m2 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+sysBP+glucose,data=train,family=binomial)
bic.original.5.best.m3 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol+sysBP+glucose,data=train,family=binomial)
bic.original.5.best.m4 <- glm(TenYearCHD~male+age+sysBP+glucose,data=train,family=binomial)
bic.original.5.best.m5 <- glm(TenYearCHD~male+age+cigsPerDay+prevalentHyp+totChol+sysBP+BMI+glucose,data=train,family=binomial)

cv.err.bic.original.5.best.m1 <- cv.glm(train,bic.original.5.best.m1,K=10)$delta[1]
cv.err.bic.original.5.best.m2 <- cv.glm(train,bic.original.5.best.m2,K=10)$delta[1]
cv.err.bic.original.5.best.m3 <- cv.glm(train,bic.original.5.best.m3,K=10)$delta[1]
cv.err.bic.original.5.best.m4 <- cv.glm(train,bic.original.5.best.m4,K=10)$delta[1]
cv.err.bic.original.5.best.m5 <- cv.glm(train,bic.original.5.best.m5,K=10)$delta[1]
cv.errors.bic.original <- c(cv.err.bic.original.5.best.m1,cv.err.bic.original.5.best.m2,cv.err.bic.original.5.best.m3,cv.err.bic.original.5.best.m4,cv.err.bic.original.5.best.m5)
plot(cv.errors.bic.original,main="BIC-Original CV Errors vs Variables", xlab="Model", ylab="CV Errors", type="b")
cv.errors.bic.original

which.min(cv.errors.bic.original)
bic_models = c('bic.original.5.best.m1','bic.original.5.best.m2','bic.original.5.best.m3', 'bic.original.5.best.m4','bic.original.5.best.m5')
aic_models = c('aic.original.5.best.m1','aic.original.5.best.m2','aic.original.5.best.m3','aic.original.5.best.m4','aic.original.5.best.m5')
bic_up = c('bic.upsampled.5.best.m1','bic.upsampled.5.best.m2','bic.upsampled.5.best.m3','bic.upsampled.5.best.m4','bic.upsampled.5.best.m5')
aic_up = c('aic.upsampled.5.best.m1','aic.upsampled.5.best.m2','aic.upsampled.5.best.m3','aic.upsampled.5.best.m4','aic.upsampled.5.best.m5')


## BEST 4 MODELS
## AIC UPSAMPLED
aic.upsampled.final <- get(aic_up[which.min(cv.errors.aic.upsampled)])
summary(aic.upsampled.final)
## AIC ORIGINAL
aic.original.final <- get(aic_models[which.min(cv.errors.aic.original)])
summary(aic.original.final)
## BIC UPSAMPLED
bic.upsampled.final <- get(bic_up[which.min(cv.errors.bic.upsampled)])
summary(bic.upsampled.final)
## BIC ORIGINAL

bic.original.final <- get(bic_models[which.min(cv.errors.bic.original)])
summary(bic.original.final)

#' 
#' ## DEFINING FUNCTIONS FOR LATER
## ----------------------------------------------------------------------------------------------------------------
cv_pruned = function(model_name, size){
  cv_model = cv.tree(get(model_name), K =10, FUN = prune.misclass)
  print(cv_model)
  plot(cv_model$size, cv_model$dev, type = "b", main = "Cross Validation: Deviance versus size",  ylab = 'Number of obs misclassified', xlab = 'Number of Nodes')
  nn = cv_model$size[which.min(cv_model$dev)]
  if (size == 0){
    prune_model = prune.misclass(get(model_name), best = nn)
    plot(prune_model)
    title("Pruned Classification Tree for Framingham Data Set")
    text(prune_model, pretty = 0)
  }
  else {
    prune_model = prune.misclass(get(model_name), best = size)
    plot(prune_model)
    title("Pruned Classification Tree for Framingham Data Set")
    text(prune_model, pretty = 0)
  }
  return(prune_model)
}

plotting.oob = function(model_name){
  oob.error.data = data.frame(Trees = rep(1:nrow(get(model_name)$err.rate), times = 3),
                            Type = rep(c("OOB", "No Heart Disease","Heart Disease"), each = nrow(get(model_name)$err.rate)),
                            Error = c(get(model_name)$err.rate[,'OOB'],
                                      get(model_name)$err.rate[,'No Heart Disease'],
                                      get(model_name)$err.rate[,'Heart Disease']))
  ggplot(data = oob.error.data, aes(x = Trees, y = Error)) +
        geom_line(aes(color = Type))

}

analyse_train_confusion = function(cmatrix){
  m2 = cmatrix[1,1]/(cmatrix[1,1]+ cmatrix[2,1])
  m3 = cmatrix[2,2]/(cmatrix[1,2]+cmatrix[2,2])
  return(list('sens' = m2, 'spec' = m3))
}

#' 
#' 
#' ## DECISION TREES before
## ----------------------------------------------------------------------------------------------------------------
tree.framingham = tree(TenYearCHD~., data =train, y = TRUE, model = TRUE)
summary(tree.framingham)
plot(tree.framingham)
text(tree.framingham, pretty = 0)

#' 
#' ## DECISION TREES after
## ----------------------------------------------------------------------------------------------------------------
# INITIAL TREES AFTER RESAMPLING
set.seed(1)
tree.framingham.upsampled = tree(TenYearCHD~., data =upsampled_train, y = TRUE, model = TRUE)
summary(tree.framingham.upsampled)
plot(tree.framingham.upsampled)
text(tree.framingham.upsampled, pretty = 0)

# APPLYING CV ANALYSIS
result.upsampled = cv_pruned('tree.framingham.upsampled',0)
summary(result.upsampled)


#' 
#' ## BAGGING
## ----------------------------------------------------------------------------------------------------------------
set.seed(1)
bag.framingham = randomForest(TenYearCHD~., data = train, mtry = 15, 
                              importance = TRUE, ntree = 150)
bag.framingham.upsampled = randomForest(TenYearCHD~., data = upsampled_train, mtry = 15, 
                              importance = TRUE, ntree = 200)


bag.framingham
bag.framingham.upsampled
analyse_train_confusion(bag.framingham$confusion)
analyse_train_confusion(bag.framingham.upsampled$confusion)

# PLOTTING OOB ERROR DATA
plotting.oob('bag.framingham')
plotting.oob('bag.framingham.upsampled')

# IMPORTANCE
importance(bag.framingham.upsampled)
varImpPlot(bag.framingham.upsampled)

#' 
#' 
#' ## RANDOM FOREST
## ----------------------------------------------------------------------------------------------------------------
set.seed(1)
# ORIGINAL DATA
rf.framingham = randomForest(TenYearCHD~., data = train, ntree = 200)
rf.framingham.upsampled = randomForest(TenYearCHD~., data = upsampled_train, ntree= 200, importance = TRUE)

rf.framingham
rf.framingham.upsampled
analyse_train_confusion(rf.framingham$confusion)
analyse_train_confusion(rf.framingham.upsampled$confusion)

importance(rf.framingham.upsampled)
varImpPlot(rf.framingham.upsampled)
analyse_train_confusion(rf.framingham$confusion)
analyse_train_confusion(rf.framingham.upsampled$confusion)

plotting.oob('rf.framingham')
plotting.oob('rf.framingham.upsampled')

#' 
#' ## PERFORMANCE ON TEST DATA
## ----------------------------------------------------------------------------------------------------------------
set.seed(1)
results_df = data.frame()
models = c('tree.framingham.upsampled','bag.framingham.upsampled','rf.framingham.upsampled','aic.upsampled.final', 'aic.original.final', 'bic.upsampled.final', 'bic.original.final', 'rf.framingham')

get_metrics = function(model_name, num){
  if ((startsWith(model_name,'aic') | (startsWith(model_name,'bic')))){
    model_pred = predict(get(model_name), test, type = "response")
    model_pred <- ifelse(model_pred > 0.5, "Heart Disease", "No Heart Disease")
    cmatrix = table(model_pred, test$TenYearCHD)
  }
  else {
    model_pred = predict(get(model_name), test, type = "class")
    cmatrix = table(model_pred, test$TenYearCHD)
  }
  # print(model_name)
  # print(cmatrix)
  m1 = cmatrix[2,2]/(cmatrix[1,2]+cmatrix[2,2])
  m2 = cmatrix[1,1]/(cmatrix[1,1]+ cmatrix[2,1])
  m3 = (cmatrix[1,2]+cmatrix[2,1])/nrow(test)
  return(data.frame('model' = model_name, 'err' = m3, 'sens' = m2, 'spec' = m1))
}

for (i in 1:length(models)){
  results_df = rbind(get_metrics(models[i]), results_df)
}

print(results_df)

#' 
## ----------------------------------------------------------------------------------------------------------------
## Upsampling framingham dataset
framingham_x = framingham[,-16]
framingham_y = framingham$TenYearCHD
framingham_upsampled <- upSample(framingham_x, framingham_y, list = FALSE, yname = "TenYearCHD")

## Refitting Trees model
tree.framingham.final = tree(TenYearCHD~., data =framingham_upsampled, y = TRUE, model = TRUE)
summary(tree.framingham.upsampled)
plot(tree.framingham.upsampled)
text(tree.framingham.upsampled, pretty = 0)

#' 
#' 
#' 
#' ## EXPLORATION
## ----------------------------------------------------------------------------------------------------------------
attach(framingham)
male.table <- table(TenYearCHD, male)
male.table
age.boxplot <- boxplot(framingham$age~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="Age")
age.boxplot
education.table <- table(TenYearCHD,education)
education.table
currentsmoker.table <- table(TenYearCHD,currentSmoker)
currentsmoker.table
cigsperday.boxplot <- boxplot(cigsPerDay~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="Cigs Per Day")
cigsperday.boxplot

bpmeds.table <- table(TenYearCHD,BPMeds)
bpmeds.table

prevalentstroke.table <- table(TenYearCHD,prevalentStroke)
prevalentstroke.table

prevalenthyp.table <- table(TenYearCHD,prevalentHyp)
prevalenthyp.table

diabetes.table <- table(TenYearCHD,diabetes)
diabetes.table

totchol.boxplot <- boxplot(totChol~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="Total Cholesterol")
totchol.boxplot

sysbp.boxplot <- boxplot(sysBP~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="Systolic BP")
sysbp.boxplot

diabp.boxplot <- boxplot(diaBP~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="Diastolic BP")
diabp.boxplot

bmi.boxplot <- boxplot(BMI~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="BMI")
bmi.boxplot

heartrate.boxplot <- boxplot(heartRate~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="Heart Rate")
heartrate.boxplot

glucose.boxplot <- boxplot(glucose~TenYearCHD,col=c("blue","red"),
                       xlab="10-year CHD",ylab="Glucose Levels")
glucose.boxplot

#' 
#' 
#' ## PROPORTION TESTING
## ----------------------------------------------------------------------------------------------------------------
male.proptest <- prop.test(c(250,307),n=c(2034,1622),alternative="two.sided",conf.level=0.99,correct=FALSE)
male.proptest
education.proptest <- prop.test(c(291,131,75,60),n=c(1526,1101,606,423),alternative="two.sided",conf.level=0.99,correct=FALSE)
education.proptest 
currentsmoker.proptest <- prop.test(c(272,285),n=c(1868,1788),alternative="two.sided",conf.level=0.99,correct=FALSE)
currentsmoker.proptest
bpmeds.proptest <- prop.test(c(520,37),n=c(3545,111),alternative="two.sided",conf.level=0.99,correct=FALSE)
bpmeds.proptest
prevalentstroke.proptest <- prop.test(c(549,8),n=c(3635,21),alternative="two.sided",conf.level=0.99,correct=FALSE)
prevalentstroke.proptest
prevalenthyp.proptest <- prop.test(c(273,284),n=c(2517,1139),alternative="two.sided",conf.level=0.99,correct=FALSE)
prevalenthyp.proptest
diabetes.proptest <- prop.test(c(522,35),n=c(3557,99),alternative="two.sided",conf.level=0.99,correct=FALSE)
diabetes.proptest

#' 
#' ## Data Exploration: 2 Sample t-test for non binary variables
## ----------------------------------------------------------------------------------------------------------------
data.with.TYCHD <- filter(framingham,TenYearCHD=="No Heart Disease")
data.without.TYCHD <- filter(framingham,TenYearCHD=="Heart Disease")

age.with.TYCHD <- data.with.TYCHD$age
age.without.TYCHD <- data.without.TYCHD$age
age.ttest <- t.test(age.without.TYCHD,age.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
age.ttest

sysbp.with.TYCHD <- data.with.TYCHD$sysBP
sysbp.without.TYCHD <- data.without.TYCHD$sysBP
sysbp.ttest <- t.test(sysbp.without.TYCHD,sysbp.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
sysbp.ttest

cigsperday.with.TYCHD <- data.with.TYCHD$cigsPerDay
cigsperday.without.TYCHD <- data.without.TYCHD$cigsPerDay
cigsperday.ttest <- t.test(cigsperday.without.TYCHD,cigsperday.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
cigsperday.ttest

totchol.with.TYCHD <- data.with.TYCHD$totChol
totchol.without.TYCHD <- data.without.TYCHD$totChol
totchol.ttest <- t.test(totchol.without.TYCHD,totchol.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
totchol.ttest

diabp.with.TYCHD <- data.with.TYCHD$diaBP
diabp.without.TYCHD <- data.without.TYCHD$diaBP
diabp.ttest <- t.test(diabp.without.TYCHD,diabp.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
diabp.ttest

bmi.with.TYCHD <- data.with.TYCHD$BMI
bmi.without.TYCHD <- data.without.TYCHD$BMI
bmi.ttest <- t.test(bmi.without.TYCHD,bmi.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
bmi.ttest

hr.with.TYCHD <- data.with.TYCHD$heartRate
hr.without.TYCHD <- data.without.TYCHD$heartRate
hr.ttest <- t.test(hr.without.TYCHD,hr.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
hr.ttest

gl.with.TYCHD <- data.with.TYCHD$glucose
gl.without.TYCHD <- data.without.TYCHD$glucose
gl.ttest <- t.test(gl.without.TYCHD,gl.with.TYCHD,alternative="two.sided",mu=0,var.equal=FALSE,conf.level=0.99)
gl.ttest

#' 
#' ## INTERACTION TERMS
## ----------------------------------------------------------------------------------------------------------------
interaction.data <- dplyr::select(framingham,male,age,cigsPerDay,prevalentStroke,prevalentHyp,totChol,sysBP,BMI,heartRate,glucose)
ggpairs(interaction.data)

