###PANDADOC INDENTIFY REGRESSION

##Load data from local machine and reformat
id_data = read.csv("/Users/austin.lee/Desktop/memsql/panda_doc_analysis/pandadoc_firmographic.csv")
id_data$converted_to_active[id_data$converted_to_active == 1] <- 0
id_data$converted_to_active[id_data$converted_to_active == 2] <- 1

##update country

id_data$country[id_data$state != 'NULL'] <- 'United States'

loc_to_country <- subset(id_data, country == 'NULL' & id_data$state == 'NULL', select = c(unique(location)))

###Geocode###
library(ggmap)

locations_for_geocode <- unique(loc_to_country$location)

geo_output <- geocode(as.character(locations_for_geocode), output = "more", messaging=TRUE, override_limit=TRUE
)

locations_coded <- cbind(data.frame(locations_for_geocode), data.frame(geo_output$country))

id_data$country[match(locations_coded[,1],id_data$location)] <- locations_coded[,2]

id_data$country[na.omit(match(locations_coded[,1],id_data$location))] <- locations_coded$geo_output.country[which(id_data$location %in% locations_coded[,1])]

id_data_test <- id_data

merged_id_geo <- merge(x = id_data, y = locations_coded, by = "location", all.x = TRUE)

plot(id_data$converted_to_active,id_data$employee_count)

id_data_converted <- subset(id_data, converted_to_active == 1 & status == 'Verified')
id_data_churned <- subset(id_data, converted_to_active == 0 & status == 'Verified')

id_data_converted_US <- subset(id_data, converted_to_active == 1 & status == 'Verified' & country == 'United States')
id_data_churned_US <- subset(id_data, converted_to_active == 0 & status == 'Verified' & country == 'United States')

id_data_us_verified <- subset(id_data, status == 'Verified' & country == 'United States')

mod_1 <- lm(converted_to_active ~ as.numeric(employee_count), data = id_data_us_verified)

hist(as.numeric(id_data_converted_US$employee_count))
hist(as.numeric(id_data_churned_US$employee_count))

emp_density_converted <- density(as.numeric(id_data_converted$employee_count))
emp_density_churned <- density(as.numeric(id_data_churned$employee_count))
plot(emp_density_converted, xlim = c(0,7500))
lines(emp_density_churned)