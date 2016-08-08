### Pre-processing ###
## Load Data ##

base_data = read.csv("/Users/austin.lee/Desktop/Chartio/chartio_long.csv")
self_signup <- subset(base_data, company_signup_type == 'self_signup')
sales_signup <- subset(base_data, company_signup_type == 'sales_signup')

## Reshape ##
library(reshape2)

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
n <- names(train)
f <- as.formula(paste("converted ~", paste(n[!n %in% "converted"], collapse = " + ")))
nn <- neuralnet(f,data=train,hidden=c(12,6),linear.output=TRUE, stepmax = 10000, rep = 1, act.fct = 'logistic')
plot(nn)

pr.nn <- compute(nn,test[,-1], rep = 1)
test.r <- test$converted
MSE.nn <- sum((test.r - pr.nn$net.result)^2)/nrow(test)

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


save(svm.model_c, file = "/Users/austin.lee/whalr_data/svm_model_c.RData")
save(test_scaled, file = "/Users/austin.lee/whalr_data/scaling_parameters.RData")
write.svm(svm.model_c,svm.file = "svmmodel.svm")
