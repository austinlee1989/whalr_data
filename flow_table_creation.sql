## FLOW Table Creation ##

##Create Track Table ##
drop table if exists flow.track;
create table flow.track (time_stamp int, user_id int, event varchar(64), index(event, user_id));

##load data into table (manually change infile names)##
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/flow23947635/flow_track.csv'
INTO TABLE flow.track
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(time_stamp, user_id, event);
COMMIT;


## Identify table
drop table if exists flow.identify;
Create Table flow.identify
(user_id int, name text, email varchar(128), time_stamp int, plan_name varchar(64), index(plan_name, user_id));
 
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/flow23947635/flow_identify.csv' 
INTO TABLE flow.identify
FIELDS TERMINATED BY '\t'  LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(user_id, name, email, time_stamp, plan_name);
COMMIT;

update flow.track set `event` = substring_index(event, '\n',1) where `event` like '%\n%';

select event, count(distinct user_id) as count_users, count(event) as count_events from flow.track group by 1;

select user_id, max(time_stamp) as started_trial_ts
from flow.track
where event = 'Started Trial'
group by 1;



##Update Identify to fix multi line selected plans ##
update chartio.identify set company_selected_plan = substring_index(company_selected_plan,'\n',1) where company_selected_plan like '%\n%';

##Create users table and company table##
drop table if exists chartio.company;
CREATE TABLE chartio.company 
(company_id int, company_name text, company_signup_type varchar(16), company_org_status varchar(16), company_feature_set varchar(32), company_trial_start int, company_trial_end int, company_created_at int,
	index(company_id, company_trial_start, company_trial_end))
select company_id, company_name, company_signup_type, min(company_org_status) as company_org_status, max(company_feature_set) as company_feature_set, company_trial_start, max(company_trial_end) as company_trial_end, company_created_at
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

##Converted_users- 123
drop table if exists chartio.converted_users;
create table converted_users
Select id.user_id
from chartio.identify id
inner join (select company_id from chartio.identify where company_org_status = 'active' group by company_id) active 
	on active.company_id = id.company_id
where id.time_stamp >= company_trial_start and id.time_stamp <= company_trial_end
group by id.user_id;    



##Create Domain Table
Create table `domains` (domain varchar(64), name varchar(64), description text, location varchar(2083), employees int, url varchar(2083), raised_text varchar(64), raised int , linkedin varchar(2083), crunchbase varchar(2083), twitter varchar(2083), facebook varchar(2083), push char(1), last_updated datetime, industry varchar(64), created_at datetime, index(domain, location, employees, industry), primary key(domain));
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/memsql/panda_doc_analysis/pandadoc_domains.csv'
INTO TABLE test_instance.pandadoc_domains
FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(domain, name, description, location, employees, url, raised_text, raised, linkedin, crunchbase, twitter, facebook, push, last_updated, industry, created_at);
COMMIT;