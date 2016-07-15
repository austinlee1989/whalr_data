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
plot(fit)

##nbreg
require(foreign)
require(ggplot2)
require(MASS)

nbreg <- glm.nb(converted_to_active~ . - user_id, data=mydata)
