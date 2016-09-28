### Pre-processing ###

## Pre Process ##

preprocess_data <- function (input_csv, id_features, wide_var, value_features, train_ratio, num_quant){
  library(reshape2)  
  cons_ <- paste(id_features, sep = " ", collapse = " + ")
  f_ <- as.formula(paste(c(cons_, wide_var), sep = " ", collapse = " ~ "))
  wide_data <- dcast(input_csv, f_, value.var = value_features)
  wide_data[is.na(wide_data)] <- 0
  
  # fix column names

  colnames(wide_data) <- gsub(" ", ".", names(wide_data))
  feature_names <- names(wide_data[,!(names(wide_data) %in% id_features)])
  
  # split data into train/test and scale
  
  index <- sample(1:nrow(wide_data),round(train_ratio * nrow(wide_data)))
  trs_ = scale(wide_data[index, (names(wide_data) %in% feature_names)])
  trs_id = wide_data[index, !(names(wide_data) %in% feature_names)]
  ts_ = wide_data[-index, (names(wide_data) %in% feature_names)]
  ts_id = wide_data[-index, !(names(wide_data) %in% feature_names)]
  trs_names = names(trs_)
  missing_col <- trs_names[!(trs_names %in% names(ts_))]
  trs_[,missing_col] <- 0
  ts_ = scale(ts_,attr(trs_,  "scaled:center"), attr(trs_, "scaled:scale"))
  
  ## bucket results: FUTURE RELEASE  
  train <- as.data.frame( cbind(trs_id, trs_ ))
  test <- as.data.frame( cbind( ts_id, ts_))
  detach("package:reshape2", unload=TRUE)
  to_return <- list(wide_data, train, test)
  return(to_return)
}  

##special events##

spec_events <- function(non_features, wide_df, convert_var){
  ft_names <- setdiff(names(wide_df),non_features)
  wide_df$converted <- wide_df[,names(wide_df) == convert_var]
  glm_loop <- lapply(ft_names, function(name){
    glm(wide_df$converted ~ wide_df[,name] , na.action = na.exclude, family = binomial(link = "logit"))
  })
  names(glm_loop) <- ft_names
  return(glm_loop)
}


###Inputs###
  base_data <- read.csv("/Users/austin.lee/Desktop/Chartio/chartio_long.csv")
  base_data_2 <- read.csv("/Users/austin.lee/Desktop/Chartio/chartio_long_2_20160926.csv")
  base_features <- c("company_name", "company_signup_type", "company_feature_set", "converted")
  base_wide_var <- "event_type"
  base_value <- "count_events"
  
###Functions###  
  
  new_wide_data <- preprocess_data(base_data_2, base_features, base_wide_var, base_value, .75)
  wide_df <- as.data.frame(new_wide_data[1])
  train_df <- as.data.frame(new_wide_data[2])
  test_df <- as.data.frame(new_wide_data[3])
  ft_names <- setdiff(names(wide_df),base_features)
  ### Testing spec. events
 
  spec_output <- spec_events(base_features, wide_df, "converted")
  
  ### reduce collinearity 

## testing NN mock 1:  

  library(neuralnet)
  n <- names(train_df)
  f <- as.formula(paste("converted ~", paste(ft_names, collapse = " + ")))
  nn <- neuralnet(f,data=train_df,hidden=c(15,8),linear.output=TRUE, stepmax = 10000, rep = 2)
  #plot(nn)
  
  pr.nn <- compute(nn,test_df[,(names(test_df) %in% ft_names)], rep = 1)
  test.r <- test_df$converted
  MSE.nn <- sum((test.r - pr.nn$net.result)^2)/nrow(test)  
  
  bucket_nn <- apply(data.frame(t(pr.nn$net.result)), 1, cut, c(-Inf, 0, .25, .5, .75, .9, Inf))
  
  
    
  
id_names <- names(base_data)[0:4]
pivot_var <- names(base_data)[5]
var_names <- names(base_data)[6:7] 

#****Write paste function to create formula****#

wide_base_data <- dcast(base_data, company_name + company_signup_type + company_feature_set + converted ~ event_type, value.var = 'count_events' )
wide_base_data[is.na(wide_base_data)] <- 0

## Split data- training/testing ##

mydata <- wide_base_data[,!(names(wide_base_data) %in% id_names)]
colnames(mydata) <- gsub(" ",".", names(mydata))
index <- sample(1:nrow(mydata),round(0.75*nrow(mydata)))
train <- mydata[index,]
test <- mydata[-index,]

##Alt training/testing split with orginal names intact
colnames(wide_base_data) <- gsub(" ",".", names(wide_base_data))
index <- sample(1:nrow(wide_base_data),round(0.75*nrow(wide_base_data)))
train_re <- wide_base_data[index,]
test_re <- wide_base_data[-index,]
train <- train_re[,!(names(wide_base_data) %in% id_names)]
test <- test_re[,!(names(wide_base_data) %in% id_names)]


## Mean-Subtraction/Normalization ##

train_scaled <- train[,!names(train) == 'converted']
train_conversion <- train[,names(train) == 'converted']
train_scaled <- scale(train_scaled)
train <- cbind(train_conversion, train_scaled)

test_scaled <- test[,!names(test) == 'converted']
test_conversion <- test[,names(test) == 'converted']
test_scaled <- scale(test_scaled, attr(train_scaled, "scaled:center"), attr(train_scaled, "scaled:scale"))
test <- cbind(test_conversion, test_scaled)
train <- data.frame(train)
test <- data.frame(test)

colnames(train) <- names(mydata)
colnames(test) <- names(mydata)

## PCA/Dimension Reduction ##




### Analysis/Modelling ###
## Linear Model ##
lm.fit <- lm(converted ~ . , data = train)
pr.lm <- predict(lm.fit, test)
MSE.lm <- sum((pr.lm - test$converted)^2)/nrow(test)




## Logit ##
log.fit <- glm(converted ~ . , data = train, family = 'binomial')
pr.log <- predict(log.fit, test)
log.intercept <- log.fit$coefficients[1]
pr.log_prob <- exp(log.intercept + pr.log)/(1 + exp(log.intercept + pr.log))

MSE.log <- sum((pr.log - test$converted)^2)/nrow(test)
MSE.log_prob <- sum((pr.log_prob - test$converted)^2)/nrow(test)

## NBreg ##
## Neural Net. ##
library(neuralnet)
n <- names(train_df)
f <- as.formula(paste("converted ~", paste(n[!n %in% "converted"], collapse = " + ")))
nn <- neuralnet(f,data=train_df,hidden=c(12,6),linear.output=TRUE, stepmax = 10000, rep = 2)
plot(nn)

pr.nn <- compute(nn,test[,-1], rep = 1)
test.r <- test$converted
MSE.nn <- sum((test.r - pr.nn$net.result)^2)/nrow(test)


## Random Forest
library(randomForest)

train$converted <- as.factor(train$converted)

forest <- randomForest(converted ~., data = train, ntree = 1000, maxnodes = 3)

pr.forest <- predict(forest, test[,-1])
pr.forest_actual <- cbind(pr.forest, test[,1])
table(pr.forest_actual[,1],pr.forest_actual[,2])

## SVM ##
# set gamma == 1, and experiment with cost from 1 -> 1000, once minimum MSE is found, do the same with gamma #

library(e1071)
svm.model <- svm(f,data = train, cost = 100, gamma = 160, cross = 5)
pr.svm <- predict(svm.model, test[,-1])
pr.svm_actual <- cbind(pr.svm, test[,1])
MSE.svm <- sum((pr.svm - test$converted)^2)/nrow(test)

print(MSE.svm)

## SVM C-Classification ##
svm.model_c <- svm(f,data = train, cost = 160, gamma = 5, type = 'C-classification', cross = 5, kernel = "linear")

pr.svm_c <- predict(svm.model_c, test[,-1])
pr.svm_actual_c <- cbind(pr.svm_c, test[,1])
##MSE.svm_c <- sum((pr.svm_c - test$converted)^2)/nrow(test)
table(pr.svm_actual_c[,1],pr.svm_actual_c[,2])

dev.new(width=5, height=5)
plot(pr.svm_c, train)


print(paste(MSE.lm,MSE.log_prob,MSE.nn,MSE.svm))


par(mfrow=c(2,2))
plot(test$converted,pr.log_prob,col='red',main='Real vs predicted logit',pch=18,cex=0.7)
abline(0,1,lwd=2)
legend('bottomright',legend='NN',pch=18,col='red', bty='n')

plot(test$converted,pr.lm,col='blue',main='Real vs predicted lm',pch=18, cex=0.7)
abline(0,1,lwd=2)
legend('bottomright',legend='LM',pch=18,col='blue', bty='n', cex=.95)

plot(test$converted,pr.nn$net.result,col='blue',main='Real vs predicted NN',pch=18, cex=0.7)
abline(0,1,lwd=2)
legend('bottomright',legend='LM',pch=18,col='blue', bty='n', cex=.95)

### PCA TESTING ###
pca_lm <- prcomp(train, center = TRUE)
plot(pca_lm, type ='l')
pca_lm

## Clustering ##
library(fpc)
library(cluster)
km.train <- kmeans(train, 2)
plotcluster(train,km.train$cluster)
plot(train$converted, km.train$cluster)

### Prediction/Testing/Model Selection ###
## Predict performance for all models ##
# Create table of percent of testing data points correctly predicted #


bucket_svm <- apply(data.frame(t(pr.svm)), 1, cut, c(-Inf, 0, .25, .5, .75, .9, Inf))
bucket_nn <- apply(data.frame(t(pr.nn$net.result)), 1, cut, c(-Inf, 0, .25, .5, .75, .9, Inf))
bucket_lm <- apply(data.frame(t(pr.lm)), 1, cut, c(-Inf, 0, .25, .5, .75, .9, Inf))
bucket_log_prob <- apply(data.frame(t(pr.log_prob)), 1, cut, c(-Inf, 0, .25, .5, .75, .9, Inf))
buckets <- data.frame(cbind(test$converted, bucket_svm, bucket_nn, bucket_lm, bucket_log_prob))

colnames(buckets) <- c("converted","svm","nn","lm","log_prob")
table(buckets$converted, buckets$svm)
table(buckets$converted, buckets$nn)
table(buckets$converted, buckets$lm)
table(buckets$converted, buckets$log_prob)
table(pr.svm_actual_c[,1],pr.svm_actual_c[,2])


## Compute/compare reduced chi-squared ##

## Select Model ##

## Save Model ##



### Model Decomposition ###
## Decompose PCA Variables ##
## Tie model back to orginal data ##

# SVM Classification #

test_full_svm <- cbind(pr.svm_actual_c, test_re)
convert_svm <- subset(test_full_svm, pr.svm_c == 2)
convert_svm_all <- subset(test_full_svm, converted == 1 | pr.svm_c == 2)

save(svm.model_c, file = "/Users/austin.lee/Desktop/Chartio/svm_model_c.RData")
save(test_scaled, file = "/Users/austin.lee/Desktop/Chartio/scaling_parameters.RData")
write.svm(svm.model_c,svm.file = "svmmodel.svm")




##Eye Candy
library(rgl)
library(misc3d)


## Apply Model to new leads ##

new_leads = read.csv("/Users/austin.lee/Desktop/Chartio/chartio_long_leads.csv")


## Reshape ##
library(reshape2)

id_names <- names(new_leads)[0:4]
pivot_var <- names(new_leads)[5]
var_names <- names(new_leads)[6:7] 
#****Write paste function to create formula****#

wide_new_leads <- dcast(new_leads, company_name + company_signup_type + company_feature_set + converted ~ event_type, value.var = 'count_events' )
wide_new_leads[is.na(wide_new_leads)] <- 0

## Scale Data ##

mydata_leads <- wide_new_leads[,!(names(wide_new_leads) %in% id_names)]
colnames(mydata_leads) <- gsub(" ",".", names(mydata_leads))

##add in null columns
leads_col_names <- names(mydata_leads)
train_col_names <- names(train)
missing_col <- train_col_names[!(train_col_names %in% leads_col_names)]
mydata_leads[,missing_col] <- 0

leads_scaled <- mydata_leads[,!names(mydata_leads) == 'converted']
leads_conversion <- mydata_leads[,names(mydata_leads) == 'converted']
leads_scaled <- scale(leads_scaled, attr(train_scaled, "scaled:center"), attr(train_scaled, "scaled:scale"))
leads <- cbind(leads_conversion, leads_scaled)
leads <- data.frame(leads)

colnames(leads) <- names(mydata_leads)



### List of predicted conversions ###
leads.svm.predict <- predict(svm.model_c, leads[-1])
leads.full.predict <- cbind(leads.svm.predict, wide_new_leads)

leads.svr.predict <- predict(svm.model, leads[-1])
leads.full.predict.svr <- cbind(leads.svr.predict, wide_new_leads)

leads.nn <- compute(nn,leads[,-1], rep = 1)
leads_bucket_nn <- apply(data.frame(t(leads.nn$net.result)), 1, cut, c(-Inf, 0, .25, .5, .75, .9, Inf))
leads_nn_predict <- cbind(leads_bucket_nn, wide_new_leads)

write.csv2(leads.full.predict, file = "/Users/austin.lee/Desktop/Chartio/chartio_predicted_leads.csv")

write.csv2(leads.full.predict.svr, file = "/Users/austin.lee/Desktop/Chartio/chartio_predicted_leads_svr.csv")
write.csv2(leads_nn_predict, file = "/Users/austin.lee/Desktop/Chartio/chartio_predicted_leads_nn.csv")

leads.golden <- subset(leads.full.predict, converted == 0 && leads.svm.predict == 1)

###Confusion Matrices###
table(pr.svm_actual_c[,1],pr.svm_actual_c[,2])
bucket_lead_nn <- apply(data.frame(t(leads.nn$net.result)), 1, cut, c(-Inf, 0, .25, .5, .75, .9, Inf))
leads_nn_all <- cbind(data.frame(leads), bucket_lead_nn)

table(leads_nn_all$converted, leads_nn_all$bucket_lead_nn)