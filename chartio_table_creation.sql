## Chartio Table Creation ##


#### SEVERAL DAY GAP IN DATA FROM 07/12 - 07/17 (?) ####

##Create Track Table ##
drop table if exists chartio.track;
create table chartio.track (properties_name varchar(32), user_id varchar(128), properties_details text, organization_id int, properties_category varchar(32), time_stamp int, event varchar(16),
	unique index(user_id, organization_id, properties_category, time_stamp));

SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/chartio89732323/track_merged.csv'
INTO TABLE chartio.track
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(properties_name, user_id, properties_details, organization_id, properties_category, time_stamp, event);
COMMIT;


## Identify table
drop table if exists chartio.identify;
Create Table chartio.identify
	(context_ip varchar(16), user_id varchar(128), name varchar(128), company_signup_type varchar(16), created_at int, company_org_status varchar(16), company_id int, company_feature_set varchar(32), company_trial_start int, company_trial_end int, company_name text, time_stamp int, company_created_at int, email varchar(128), company_selected_plan varchar(128)
		,unique index(user_id,company_id,time_stamp, company_signup_type, company_org_status));
        
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/chartio89732323/identify_merged.csv' 
INTO TABLE chartio.identify
FIELDS TERMINATED BY '\t'  LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(context_ip, user_id, name, company_signup_type, created_at, company_org_status, company_id, company_feature_set, company_trial_start, company_trial_end, company_name, time_stamp, company_created_at, email, company_selected_plan);
COMMIT;

##Update Identify to fix multi line selected plans ##
update chartio.identify set company_selected_plan = substring_index(company_selected_plan,'\n',1) where company_selected_plan like '%\n%';

##Create users table and company table##

###Update Company Table
#drop table if exists chartio.company;
CREATE TABLE chartio.company 
(company_id int, company_name text, company_signup_type varchar(16), company_org_status varchar(16), company_feature_set varchar(32), company_trial_start int, company_trial_end int, company_created_at int, company_last_seen int,
	unique index(company_id, company_trial_start, company_trial_end))
select company_id, company_name, company_signup_type, min(company_org_status) as company_org_status, max(company_feature_set) as company_feature_set, company_trial_start, max(company_trial_end) as company_trial_end, company_created_at, max(time_stamp) as company_last_seen
from chartio.identify
where company_org_status != "" and company_name not like '%chartio%' and company_id != 0
group by company_id, company_name, company_signup_type, company_trial_start, company_created_at;

drop table if exists chartio.users;
CREATE TABLE chartio.users
(user_id varchar(128), name varchar(128), created_at int, email varchar(128), company_id int,
	index(company_id))
select user_id, max(name) as name, created_at, email, max(company_id) as company_id
from chartio.identify
where email not like '%@chartio.com'
group by user_id, created_at, email;


## event_types table
drop table if exists chartio.event_types;
CREATE TABLE chartio.event_types
(event_id int auto_increment primary key, event_category varchar(32), event_name varchar(32))
select properties_category as event_category, properties_name as event_name 
from chartio.track
group by properties_category, properties_name;


##Company/User??- conversion outcome, actions during trial (2 series of analysis- trial conversion and upsell potential
	#count distinct events, count distinct users per event, count total events...
  

##Trialing Users (1068)##
drop table if exists chartio.trialing_users;
create table trialing_users
Select user_id
from chartio.identify id
where id.time_stamp >= company_trial_start and id.time_stamp <= company_trial_end
group by user_id;

##Converted_users- 
drop table if exists chartio.converted_users;
create table converted_users
Select id.user_id, active.company_id
from chartio.identify id
inner join (select company_id from chartio.identify where company_org_status = 'active' group by company_id) active 
	on active.company_id = id.company_id
where id.time_stamp >= company_trial_start and id.time_stamp <= company_trial_end
group by 1,2;    


##Email/Domains
drop table if exists chartio.domains;
CREATE TABLE chartio.domains (domain varchar(64), name varchar(128), location varchar(128), employees int, industry varchar(128), unique index( industry, domain));
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/Chartio/chartio_domains_20160926.csv' 
INTO TABLE chartio.domains
FIELDS TERMINATED BY ',' enclosed by '"'  LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(domain, name, location, employees, industry);
COMMIT;

drop table if exists chartio.emails;
CREATE TABLE chartio.emails (email varchar(128), employment varchar(128), location varchar(128), expertise int, domain varchar(128), unique index( expertise, domain));
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/Chartio/chartio_emails_20160926.csv' 
INTO TABLE chartio.emails
FIELDS TERMINATED BY ',' enclosed by '"'  LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(email, employment, location, expertise, domain);
COMMIT;