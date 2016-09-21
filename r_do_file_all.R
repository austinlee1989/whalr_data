##PANDADOC BEHAVIOR MODELING

mydata = read.csv("/Users/austin.lee/Desktop/memsql/panda_doc_analysis/pandadoc_final.csv")

##Switch converted to active so that binary
mydata$converted_to_active[mydata$converted_to_active == 1] <- 0
mydata$converted_to_active[mydata$converted_to_active == 2] <- 1

##Start modeling
mod <- lm(converted_to_active~ . - user_id, data=mydata)

##variables
##(Document_theme_changed + Library_Item_Block_Heading_added + Uploaded_a_template + Revision_document_duplicated + Document_Uploaded_Created_from_template + Document_Uploaded_Field_esignature_added)

mod_2 <- lm(converted_to_active ~ Document_theme_changed + Library_Item_Block_Heading_added + Uploaded_a_template + Revision_document_duplicated + Document_Uploaded_Created_from_template + Document_Uploaded_Field_esignature_added, data =mydata)


# diagnostic plots 
layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
plot(mod_2)

##nbreg
require(foreign)
require(ggplot2)
require(MASS)

nbreg <- glm.nb(converted_to_active~ . - user_id, data=mydata)

##glm binomial/logit restricted:

logit <- glm(converted_to_active~ . - user_id, data=mydata, family = "binomial")
summary(logit)

##convert to odds-ratio
logit_sum <- summary(logit)
logit_exp_coef <- exp(logit_sum$coefficients[,1])
logit_p_value <- logit_sum$coefficients[,4]
logit_odds <- t(rbind(logit_exp_coef,logit_p_value ))
logit_odds <- logit_odds[order(-logit_odds[,1]),]



layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
plot(logit)

###Repeat for full results dataset###

mydata_all = read.csv("/Users/austin.lee/Desktop/memsql/panda_doc_analysis/pandadoc_for_r_all_columns.csv")

mydata_all$converted_to_active[mydata$converted_to_active == 1] <- 0
mydata_all$converted_to_active[mydata$converted_to_active == 2] <- 1

logit_all <- glm(converted_to_active~ . - user_id, data=mydata_all, family = "binomial")
summary(logit_all)
confit.default(logit_all)

layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
plot(logit_all)

##convert to odds-ratio
logit_sum_all <- summary(logit_all)
logit_exp_coef <- t(exp(logit_sum_all$coefficients[,1]))
logit_p_value <- t(logit_sum_all$coefficients[,4])
logit_odds_all <- rbind(logit_exp_coef,logit_p_value )
logit_odds_all <- t(logit_odds_all)
logit_odds_all <- logit_odds_all[order(-logit_odds_all[,1]),]


logit_odds_all_sig_only <- logit_odds_all[logit_odds_all[,2] < .05,]
logit_odds_sig_only <- logit_odds[logit_odds[,2] < .05,]

logit_final <- glm(converted_to_active~ . , data=mydata_all_sig, family = "binomial")
summary(logit_final)

mydata_all_sig <- mydata_all[,( names(mydata_all) %in% logit_odds_all_sig_only[,0])]



##Form dataframe of summary stats


drops <- c("user_id", "Account...Charged", "Account...Upgraded", "Account...Plan.changed")
working_data <- mydata_all[, !(names(mydata_all) %in% drops)]

##Pretty K-means clustering plot



sig_names <- c("converted_to_active"
,"Document_Uploaded_Field_text_field_added"    
,"Library_Item_Block_Heading_added"           
,"Document_Uploaded_Field_esignature_added"   
,"Document_Uploaded_Created_from_template"     
,"Team_Member_Joined"                          
,"Document_theme_changed"                      
,"Template_Editor_Block_Heading_added"         
,"Revision_document_duplicated"                
,"Document_theme_applied"                      
,"Revision_rearranged_widgets"                 
,"Template_Editor_Created"                     
,"Document_Editor_Block_Page_break_added"      
,"Catalog_Item_created"                        
,"Created_document_from_template"              
,"Document_Editor_Created_from_public_template"
,"Created_Document_from_Public_Template"       
,"Template_Editor_Block_Image_removed"         
,"Library_item_used"                           
,"Document_Uploaded_Field_added")
clustering_data <- mydata[, (names(mydata) %in% sig_names)]

p_conversion <- clustering_data 

prediction <- predict(logit, data = mydata)
mydata_prediction <- cbind(mydata, prediction)
data_for_plot <- cbind(mydata_prediction, km$cluster)

km    <- kmeans(prediction,3)

cluster_predict <- cbind(km$cluster,prediction)
cluster_predict_matrix <- data.matrix(cluster_predict)
cluster_predict_matrix <- data.matrix(cluster_predict[,])

cluster_predict <- cbind(cluster_predict, mydata$converted_to_active)

library(ggplot2)
ggplot(clustering_data, aes(x="Team_Member_Joined", y=converted_to_active))+geom_point(size=2, alpha=0.4)+
  stat_smooth(method="loess", colour="blue", size=1.5)+
  xlab("Frequency")+
  ylab("Probability of Detection")+
  theme_bw()


library(cluster)
library(HSAUR)
data(prediction)
km    <- kmeans(prediction,3)
dissE <- daisy(prediction) 
dE2   <- dissE^2
sk2   <- silhouette(km$cl, dE2)
plot(sk2)

library(cluster)
library(fpc)

####Eye candy for pitch:

N=1000
data=data.frame(
	Q=seq(N)
	, Freq=(runif(N,0,1)* (1 + rnorm(N, mean = 0.5, sd = 0))^5)
	, Converted=rnorm(N, mean = .63, sd = .34)
	)

ggplot(data, aes(x=Freq, y=Converted))+geom_point(size=2, alpha=0.4)+
  stat_smooth(method="loess", colour="blue", size=1.5)+
  xlab("Frequency")+
  ylab("Likelihood of Conversion")+
  theme_bw()

hist(data_for_plot[,70], breaks = 25, prob = TRUE, col = "gray", main = "Odds-Ratio of Conversion", xlab="Likelihood of Conversion Odds Bucket") 
lines(density(data_for_plot[,70], adjust = 15), col = "Blue", lwd = TRUE)


ggplot(data_for_plot, aes(x = data_for_plot[,70], y = data_for_plot$converted_to_active)) +  stat_smooth(method = "loess", colour = "blue", size = 1.5) + xlab("Event Score") + ylab("Likelihood of Conversion")+ theme_bw() + ylim(0,1)


library(cluster)
library(fpc)
grouping_data <- clustering_data[!(clustering_data[,1] == 0),]
 km_converted <- kmeans(grouping_data, 5)
 plotcluster(grouping_data,km_converted$cluster)
 
 ##dc_1 && dc_2 from principle component analysis
 
 library(plyr)
 count(km_converted$cluster)
 list_of_clusters <- t(km_converted$centers)
 
 ##PCA analysis##
 pca_test <- prcomp(grouping_data,center = TRUE)
 plot(pca_test, type = "l")

pca_all <- prcomp(clustering_data, center = TRUE)

library(ggfortify)

pca_test_all <- prcomp(mydata, center = TRUE)

autoplot(km_converted, data = grouping_data, frame = TRUE, frame.type = 'norm', loadings = TRUE)

km_all <- kmeans(clustering_data, 3)
autoplot(km_all, data = clustering_data, frame = TRUE, frame.type = 'norm')


##### Event Grouping: 
VAR 1:  Created_Document_from_Public_Template + Document_Editor_Created_from_public_template -> Created_from_public_template

Created_from_public_template <- pmax(clustering_data[,19],clustering_data[,20])
clustering_data_condensed <- cbind(clustering_data[,1:18],Created_from_public_template)

##Rerun PCA
pca_var1 <- prcomp(clustering_data_condensed, center = TRUE)
plot(pca_var1, type ='l')


### VAR 2: Created Template and used template editor 
##description: custom_template <- Template_Editor_Block_Heading_added + Template_Editor_Block_Image_removed + Document_Editor_Block_Page_break_added + Template_Editor_Created 

var2_names <- c("Template_Editor_Block_Heading_added","Template_Editor_Block_Image_removed","Document_Editor_Block_Page_break_added","Template_Editor_Created")
var2 <- clustering_data_condensed[,names(clustering_data_condensed) %in% var2_names]

clustering_data_condensed_var2 <- clustering_data_condensed[,!(names(clustering_data_condensed) %in% var2_names)]

custom_template <- pmax(var2[,1],var2[,2],var2[,3],var2[,4])
clustering_data_condensed_var2 <- cbind(clustering_data_condensed_var2,custom_template)

##Rerun PCA
pca_var2 <- prcomp(clustering_data_condensed_var2, center = TRUE)
plot(pca_var2, type ='l')
pca_var2

km_var2 <- kmeans(clustering_data_condensed_var2, 4)
autoplot(km_var2, data = clustering_data_condensed_var2, frame = TRUE)

##var_3: using_template 
var3_names <- c("Library_item_used","Created_document_from_template","Document_theme_applied")

var3 <- clustering_data_condensed_var2[,names(clustering_data_condensed_var2) %in% var3_names]

clustering_data_condensed_var3 <- clustering_data_condensed_var2[,!(names(clustering_data_condensed_var2) %in% var3_names)]

using_template <- pmax(var3[,1],var3[,2],var3[,3])

clustering_data_condensed_var3 <- cbind(clustering_data_condensed_var3,using_template)

##Rerun PCA
cor(clustering_data_condensed_var3)
pca_var3 <- prcomp(clustering_data_condensed_var3, center = TRUE)
plot(pca_var3, type ='l')
pca_var3

km_var2 <- kmeans(clustering_data_condensed_var2, 4)
autoplot(km_var2, data = clustering_data_condensed_var2, frame = TRUE)

##var_4: editing_uploaded 
var4_names <- c("Document_Uploaded_Field_text_field_added","Document_Uploaded_Field_esignature_added","Document_Uploaded_Field_added")

var4 <- clustering_data_condensed_var3[,names(clustering_data_condensed_var3) %in% var4_names]

clustering_data_condensed_var4 <- clustering_data_condensed_var3[,!(names(clustering_data_condensed_var3) %in% var4_names)]

editing_uploaded <- pmax(var4[,1],var4[,2],var4[,3])

clustering_data_condensed_var4 <- cbind(clustering_data_condensed_var4,editing_uploaded)




##test logit 
logit_var4 <- glm(converted_to_active ~ . , data = clustering_data_condensed_var4, family = "binomial")

coef_odds_var4 <- exp(logit_var4$coef)

layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
plot(logit_var2)


###Neural Networks###
index <- sample(1:nrow(clustering_data_condensed_var4),round(0.75*nrow(clustering_data_condensed_var4)))
train <- clustering_data_condensed_var4[index,]
test <- clustering_data_condensed_var4[-index,]


library(neuralnet)
n <- names(train)
f <- as.formula(paste("converted_to_active ~", paste(n[!n %in% "converted_to_active"], collapse = " + ")))
nn_2 <- neuralnet(f,data=train,hidden=c(15,4),linear.output=T)
plot(nn_2)

nn_4 <- neuralnet(f,data=train,hidden=c(7,3),linear.output=T)
plot(nn_4)




##the BIG one

mydata_nn <- mydata[,!(names(mydata) == 'user_id')]
index <- sample(1:nrow(mydata_nn),round(0.75*nrow(mydata_nn)))
train <- mydata_nn[index,]
test <- mydata_nn[-index,]

##LM
lm.fit <- glm(converted_to_active~., data=train)
summary(lm.fit)
pr.lm <- predict(lm.fit,test)
MSE.lm <- sum((pr.lm - test$converted_to_active)^2)/nrow(test)

## Logit
log.fit <- glm(converted_to_active ~ . , data = train, family = "binomial")
pr.log <- predict(log.fit,test)

### Convert to Probability ###
log.intercept <- log.fit$coefficients[1]
pr.log_prob <- exp(log.intercept + pr.log)/(1 + exp(log.intercept + pr.log))

MSE.log <- sum((pr.log - test$converted_to_active)^2)/nrow(test)
MSE.log_prob <- sum((pr.log_prob - test$converted_to_active)^2)/nrow(test)

n <- names(train)
f <- as.formula(paste("converted_to_active ~", paste(n[!n %in% "converted_to_active"], collapse = " + ")))
nn_2 <- neuralnet(f,data=train,hidden=c(40,20),linear.output=T, stepmax = 100000, rep = 10)
plot(nn_2)
save(nn_2,file ="neural_net_full.RData")

## Testing NN ##
pr.nn_1 <- compute(nn_2,test[,2:68], rep = 1)
test.r <- test$converted_to_active
MSE.nn_1 <- sum((test.r - pr.nn_1$net.result)^2)/nrow(test)

pr.nn_2 <- compute(nn_2,test[,2:68], rep = 2)
test.r2 <- test$converted_to_active
MSE.nn_2 <- sum((test.r2 - pr.nn_2$net.result)^2)/nrow(test)


## Compare models ##

print(paste(MSE.lm,MSE.log_prob,MSE.nn_1,MSE.nn_2))

par(mfrow=c(2,2))
plot(test$converted_to_active,pr.nn_2$net.result,col='red',main='Real vs predicted NN',pch=18,cex=0.7)
abline(0,1,lwd=2)
legend('bottomright',legend='NN',pch=18,col='red', bty='n')

plot(test$converted_to_active,pr.lm,col='blue',main='Real vs predicted lm',pch=18, cex=0.7)
abline(0,1,lwd=2)
legend('bottomright',legend='LM',pch=18,col='blue', bty='n', cex=.95)

plot(test$converted_to_active,pr.log_prob,col='blue',main='Real vs predicted log',pch=18, cex=0.7)
abline(0,1,lwd=2)
legend('bottomright',legend='LM',pch=18,col='blue', bty='n', cex=.95)

hist(test$converted_to_active, breaks = 25, prob = TRUE, col = "gray", main = "Prob. of Conversion", xlab="Likelihood of Conversion Prob. Bucket") 
hist(1)
lines(density(pr.log_prob, adjust = 10), col = "Blue", lwd = TRUE)
lines(density(pr.lm, adjust = 10), col = "Red", lwd = TRUE)
lines(density(pr.nn_2$net.result, adjust = 10), col = "Green", lwd = TRUE)


### Back to linear model ###

##convert to odds-ratio
lm.fit_sum <- summary(lm.fit)
lm_coef <- t(lm.fit_sum$coefficients[,1])
lm.fit_p_value <- t(lm.fit_sum$coefficients[,4])
lm_all <- rbind(lm_coef,lm.fit_p_value )
lm_all <- t(lm_all)
lm_all <- lm_all[order(-lm_all[,1]),]


lm_all_sig_only <- lm_all[lm_all[,2] < .05,]

###PCA for lm

pca_lm <- prcomp(train, center = TRUE)
plot(pca_lm, type ='l')
pca_lm
