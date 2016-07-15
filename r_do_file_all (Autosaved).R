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

##glm binomial restricted:

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


