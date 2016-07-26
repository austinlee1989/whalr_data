## Chartio Table Creation ##

##Create Track Table ##
create table chartio.track (properties_name varchar(32), user_id varchar(128), properties_details text, organization_id int, properties_category varchar(32), time_stamp int, event varchar(16),
	index(user_id, organization_id, properties_category, time_stamp));

##load data into table (manually change infile names)##
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/chartio89732323/track/chartio89732323_track20160710.csv'
INTO TABLE chartio.track
FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(properties_name, user_id, properties_details, organization_id, properties_category, time_stamp, event);
COMMIT;

## Identify table
Create Table chartio.identify
	(context_ip varchar(16), user_id varchar(128), name varchar(128), company_signup_type varchar(16), created_at int, company_org_status varchar(16), company_id int, company_feature_set varchar(32), company_trial_start int, company_trial_end int, company_name text, time_stamp int, company_created_at int, email varchar(128), company_selected_plan varchar(128)
		,index(user_id,company_id,time_stamp, company_signup_type, company_org_status));
        
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/chartio89732323/identify/chartio89732323_identify20160710.csv' 
INTO TABLE chartio.identify
FIELDS TERMINATED BY ','     ENCLOSED BY '"' LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(context_ip, user_id, name, company_signup_type, created_at, company_org_status, company_id, company_feature_set, company_trial_start, company_trial_end, company_name, time_stamp, company_created_at, email, company_selected_plan);
COMMIT;

##Update Identify to fix multi line selected plans ##
update chartio.identify set company_selected_plan = substring_index(company_selected_plan,'\n',1);

##Create users table and company table##
select company_id, company_name, company_selected_plan, company_signup_type, company_org_status, company_feature_set, company_trial_start, company_trial_end, company_created_at
	,count(distinct company_id)
from chartio.identify
group by company_id, company_name, company_selected_plan, company_signup_type, company_org_status, company_feature_set, company_trial_start, company_trial_end, company_created_at;
