##load data into table##

SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/panda43584783/panda43584783_track.csv'
INTO TABLE test_instance.panda43584783_track
FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(user_id,event,anonymous_id,time);
COMMIT;

## Identify table
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/working/output/panda43584783/panda43584783_identify.csv' 
INTO TABLE test_instance.panda43584783_identify 
FIELDS TERMINATED BY ','     ENCLOSED BY '"' LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(user_id,anonymous_id,name,time,members_count,email,subscription_state);
COMMIT;


##Create Tables of Unique Users

CREATE TABLE if not exists `pandadoc_users` 
Select user_id, email 
from test_instance.panda43584783_identify id
group by user_id, email;

##Track: Events table
drop table pandadoc_events;
create table if not exists `pandadoc_events` (event_id int auto_increment primary key, event_type_0 varchar(128), event_type_1 varchar(128), event_type_2 varchar(128), event_name varchar(128), index(event_name))
select case when greatest(locate("-",event_name),locate(":",event_name)) > 0 
	then trim(left(event_name, greatest(locate("-",event_name),locate(":",event_name)) - 1)) 
		else event_name
	end 
	as event_type_0
	,case when locate("-",event_name) > 0 then reverse(substring_index(reverse(substring_index(event_name,'-',2)),'-',1))
			when locate(":",event_name) > 0 then reverse(substring_index(reverse(substring_index(event_name,':',2)),':',1))
			end 
		as event_type_1
	,	case when locate("-",event_name) > 0 and reverse(substring_index(reverse(event_name),'-',1)) <> reverse(substring_index(reverse(substring_index(event_name,'-',2)),'-',1)) 
				then reverse(substring_index(reverse(event_name),'-',1)) 
			when locate(":",event_name) > 0  <> reverse(substring_index(reverse(substring_index(event_name,':',2)),':',1)) 
				then reverse(substring_index(reverse(event_name),':',1)) 
            end
			as event_type_2
	, event_name
from (select event as event_name from test_instance.panda43584783_track group by event) aa
;

##subscription status change table

##create temp table with all subscription states/user_id/timestamps

create temporary table if not exists temp_sub_status
select time as time_stamp
			,user_id
			,substring(subscription_state, 1, char_length(subscription_state) - 1) as subscription_state
		from panda43584783_identify
		where trim(subscription_state) > ''
		group by time_stamp
			,user_id
			,substring(subscription_state, 1, char_length(subscription_state) - 1);

## create table of trialing to trial_ended/conversion

create table pandadoc_trial_outcome (user_id int, min_trialing_ts int, min_active_ts int, min_cancelled_ts int, min_assessing_ts int, converted_to_active int, index(user_id, converted_to_active))
select aaa.*
	, case when min_trial_ended_ts is not null and min_active_ts is not null then 2
		when min_trial_ended_ts is not null and min_active_ts is null then 1 
        else 0 end as converted_to_active
from (select user_id
    , min(case when tss.subscription_state = 'trialing' then time_stamp end) as min_trialing_ts
    , min(case when tss.subscription_state = 'active' then time_stamp end) as min_active_ts
    , min(case when tss.subscription_state = 'canceled' then time_stamp end) as min_cancelled_ts
    , min(case when tss.subscription_state = 'trial_ended' then time_stamp end) as min_trial_ended_ts
    , min(case when tss.subscription_state = 'assessing' then time_stamp end) as min_assessing_ts
from temp_sub_status tss
group by user_id
having count(case when tss.subscription_state = 'trialing' then 1 end) > 0) aaa;

##Create pandadoc_event_conversion table
select * from pandadoc_trial_outcome where min_trial_ended_ts is not null;


select pto.user_id
			, pto.min_trial_ended_ts
			, pto.converted_to_active
			, track.time as event_ts
			, track.event as event_name
		from (select * from pandadoc_trial_outcome where converted_to_active = 1) pto
			left join panda43584783_track track
				on track.user_id = pto.user_id and pto.min_trial_ended_ts > track.time;


## Create table of track w/only users with user_id
create table pandadoc_track_users (user_id int, event_name varchar(128), time_stamp int,  index(user_id) )
select user_id, event as event_name, time as time_stamp
from panda43584783_track
where user_id != 'null' and user_id not like 'foobar%';

##create indexed table of boosh emails
create table pandadoc_emails_indexed (email varchar(128), domain text, firstname text, lastname text, employment text, location text, linkedin text, github text, alt_company_name text, method text, confidence int, status text, last_updated datetime, expertise text, recent_job_title text, recent_job_start_at text, recent_university text, recent_degree text, recent_graduation_year int, created_at text, index(email)) 
select * from pandadoc_emails;
 
## create indexed copy
create table pandadoc_users_emails (user_id int, email varchar(128), domain text, firstname text, lastname text, employment text, location text, linkedin text, github text, alt_company_name text, method text, confidence int, status text, last_updated datetime, expertise text, recent_job_title text, recent_job_start_at text, recent_university text, recent_degree text, recent_graduation_year int, created_at text, index(email, user_id)) 
select users.user_id as user_id
	, emails.*
from pandadoc_users users
left join pandadoc_emails_indexed emails
	on users.email = emails.email;
##Drop unindexed email table
drop table pandadoc_emails;

## State/Country information ##
create table tbl_state
(
state_id   smallint    unsigned not null auto_increment comment 'PK: Unique state ID',
state_name varchar(32) not null comment 'State name with first letter capital',
state_abbr varchar(8)  comment 'Optional state abbreviation (US is 2 capital letters)',

primary key (state_id)
)

charset utf8
collate utf8_unicode_ci
;


insert into tbl_state
values
(NULL, 'Alabama', 'AL'),
(NULL, 'Alaska', 'AK'),
(NULL, 'Arizona', 'AZ'),
(NULL, 'Arkansas', 'AR'),
(NULL, 'California', 'CA'),
(NULL, 'Colorado', 'CO'),
(NULL, 'Connecticut', 'CT'),
(NULL, 'Delaware', 'DE'),
(NULL, 'District of Columbia', 'DC'),
(NULL, 'Florida', 'FL'),
(NULL, 'Georgia', 'GA'),
(NULL, 'Hawaii', 'HI'),
(NULL, 'Idaho', 'ID'),
(NULL, 'Illinois', 'IL'),
(NULL, 'Indiana', 'IN'),
(NULL, 'Iowa', 'IA'),
(NULL, 'Kansas', 'KS'),
(NULL, 'Kentucky', 'KY'),
(NULL, 'Louisiana', 'LA'),
(NULL, 'Maine', 'ME'),
(NULL, 'Maryland', 'MD'),
(NULL, 'Massachusetts', 'MA'),
(NULL, 'Michigan', 'MI'),
(NULL, 'Minnesota', 'MN'),
(NULL, 'Mississippi', 'MS'),
(NULL, 'Missouri', 'MO'),
(NULL, 'Montana', 'MT'),
(NULL, 'Nebraska', 'NE'),
(NULL, 'Nevada', 'NV'),
(NULL, 'New Hampshire', 'NH'),
(NULL, 'New Jersey', 'NJ'),
(NULL, 'New Mexico', 'NM'),
(NULL, 'New York', 'NY'),
(NULL, 'North Carolina', 'NC'),
(NULL, 'North Dakota', 'ND'),
(NULL, 'Ohio', 'OH'),
(NULL, 'Oklahoma', 'OK'),
(NULL, 'Oregon', 'OR'),
(NULL, 'Pennsylvania', 'PA'),
(NULL, 'Rhode Island', 'RI'),
(NULL, 'South Carolina', 'SC'),
(NULL, 'South Dakota', 'SD'),
(NULL, 'Tennessee', 'TN'),
(NULL, 'Texas', 'TX'),
(NULL, 'Utah', 'UT'),
(NULL, 'Vermont', 'VT'),
(NULL, 'Virginia', 'VA'),
(NULL, 'Washington', 'WA'),
(NULL, 'West Virginia', 'WV'),
(NULL, 'Wisconsin', 'WI'),
(NULL, 'Wyoming', 'WY')
;

CREATE TABLE `apps_countries` (
`id` int(11) NOT NULL auto_increment,
`country_code` varchar(2) NOT NULL default '',
`country_name` varchar(100) NOT NULL default '',
PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
-- 
-- Dumping data for table `apps_countries`
-- 
INSERT INTO `apps_countries` VALUES (null, 'AF', 'Afghanistan');
INSERT INTO `apps_countries` VALUES (null, 'AL', 'Albania');
INSERT INTO `apps_countries` VALUES (null, 'DZ', 'Algeria');
INSERT INTO `apps_countries` VALUES (null, 'DS', 'American Samoa');
INSERT INTO `apps_countries` VALUES (null, 'AD', 'Andorra');
INSERT INTO `apps_countries` VALUES (null, 'AO', 'Angola');
INSERT INTO `apps_countries` VALUES (null, 'AI', 'Anguilla');
INSERT INTO `apps_countries` VALUES (null, 'AQ', 'Antarctica');
INSERT INTO `apps_countries` VALUES (null, 'AG', 'Antigua and Barbuda');
INSERT INTO `apps_countries` VALUES (null, 'AR', 'Argentina');
INSERT INTO `apps_countries` VALUES (null, 'AM', 'Armenia');
INSERT INTO `apps_countries` VALUES (null, 'AW', 'Aruba');
INSERT INTO `apps_countries` VALUES (null, 'AU', 'Australia');
INSERT INTO `apps_countries` VALUES (null, 'AT', 'Austria');
INSERT INTO `apps_countries` VALUES (null, 'AZ', 'Azerbaijan');
INSERT INTO `apps_countries` VALUES (null, 'BS', 'Bahamas');
INSERT INTO `apps_countries` VALUES (null, 'BH', 'Bahrain');
INSERT INTO `apps_countries` VALUES (null, 'BD', 'Bangladesh');
INSERT INTO `apps_countries` VALUES (null, 'BB', 'Barbados');
INSERT INTO `apps_countries` VALUES (null, 'BY', 'Belarus');
INSERT INTO `apps_countries` VALUES (null, 'BE', 'Belgium');
INSERT INTO `apps_countries` VALUES (null, 'BZ', 'Belize');
INSERT INTO `apps_countries` VALUES (null, 'BJ', 'Benin');
INSERT INTO `apps_countries` VALUES (null, 'BM', 'Bermuda');
INSERT INTO `apps_countries` VALUES (null, 'BT', 'Bhutan');
INSERT INTO `apps_countries` VALUES (null, 'BO', 'Bolivia');
INSERT INTO `apps_countries` VALUES (null, 'BA', 'Bosnia and Herzegovina');
INSERT INTO `apps_countries` VALUES (null, 'BW', 'Botswana');
INSERT INTO `apps_countries` VALUES (null, 'BV', 'Bouvet Island');
INSERT INTO `apps_countries` VALUES (null, 'BR', 'Brazil');
INSERT INTO `apps_countries` VALUES (null, 'IO', 'British Indian Ocean Territory');
INSERT INTO `apps_countries` VALUES (null, 'BN', 'Brunei Darussalam');
INSERT INTO `apps_countries` VALUES (null, 'BG', 'Bulgaria');
INSERT INTO `apps_countries` VALUES (null, 'BF', 'Burkina Faso');
INSERT INTO `apps_countries` VALUES (null, 'BI', 'Burundi');
INSERT INTO `apps_countries` VALUES (null, 'KH', 'Cambodia');
INSERT INTO `apps_countries` VALUES (null, 'CM', 'Cameroon');
INSERT INTO `apps_countries` VALUES (null, 'CA', 'Canada');
INSERT INTO `apps_countries` VALUES (null, 'CV', 'Cape Verde');
INSERT INTO `apps_countries` VALUES (null, 'KY', 'Cayman Islands');
INSERT INTO `apps_countries` VALUES (null, 'CF', 'Central African Republic');
INSERT INTO `apps_countries` VALUES (null, 'TD', 'Chad');
INSERT INTO `apps_countries` VALUES (null, 'CL', 'Chile');
INSERT INTO `apps_countries` VALUES (null, 'CN', 'China');
INSERT INTO `apps_countries` VALUES (null, 'CX', 'Christmas Island');
INSERT INTO `apps_countries` VALUES (null, 'CC', 'Cocos (Keeling) Islands');
INSERT INTO `apps_countries` VALUES (null, 'CO', 'Colombia');
INSERT INTO `apps_countries` VALUES (null, 'KM', 'Comoros');
INSERT INTO `apps_countries` VALUES (null, 'CG', 'Congo');
INSERT INTO `apps_countries` VALUES (null, 'CK', 'Cook Islands');
INSERT INTO `apps_countries` VALUES (null, 'CR', 'Costa Rica');
INSERT INTO `apps_countries` VALUES (null, 'HR', 'Croatia (Hrvatska)');
INSERT INTO `apps_countries` VALUES (null, 'CU', 'Cuba');
INSERT INTO `apps_countries` VALUES (null, 'CY', 'Cyprus');
INSERT INTO `apps_countries` VALUES (null, 'CZ', 'Czech Republic');
INSERT INTO `apps_countries` VALUES (null, 'DK', 'Denmark');
INSERT INTO `apps_countries` VALUES (null, 'DJ', 'Djibouti');
INSERT INTO `apps_countries` VALUES (null, 'DM', 'Dominica');
INSERT INTO `apps_countries` VALUES (null, 'DO', 'Dominican Republic');
INSERT INTO `apps_countries` VALUES (null, 'TP', 'East Timor');
INSERT INTO `apps_countries` VALUES (null, 'EC', 'Ecuador');
INSERT INTO `apps_countries` VALUES (null, 'EG', 'Egypt');
INSERT INTO `apps_countries` VALUES (null, 'SV', 'El Salvador');
INSERT INTO `apps_countries` VALUES (null, 'GQ', 'Equatorial Guinea');
INSERT INTO `apps_countries` VALUES (null, 'ER', 'Eritrea');
INSERT INTO `apps_countries` VALUES (null, 'EE', 'Estonia');
INSERT INTO `apps_countries` VALUES (null, 'ET', 'Ethiopia');
INSERT INTO `apps_countries` VALUES (null, 'FK', 'Falkland Islands (Malvinas)');
INSERT INTO `apps_countries` VALUES (null, 'FO', 'Faroe Islands');
INSERT INTO `apps_countries` VALUES (null, 'FJ', 'Fiji');
INSERT INTO `apps_countries` VALUES (null, 'FI', 'Finland');
INSERT INTO `apps_countries` VALUES (null, 'FR', 'France');
INSERT INTO `apps_countries` VALUES (null, 'FX', 'France, Metropolitan');
INSERT INTO `apps_countries` VALUES (null, 'GF', 'French Guiana');
INSERT INTO `apps_countries` VALUES (null, 'PF', 'French Polynesia');
INSERT INTO `apps_countries` VALUES (null, 'TF', 'French Southern Territories');
INSERT INTO `apps_countries` VALUES (null, 'GA', 'Gabon');
INSERT INTO `apps_countries` VALUES (null, 'GM', 'Gambia');
INSERT INTO `apps_countries` VALUES (null, 'GE', 'Georgia');
INSERT INTO `apps_countries` VALUES (null, 'DE', 'Germany');
INSERT INTO `apps_countries` VALUES (null, 'GH', 'Ghana');
INSERT INTO `apps_countries` VALUES (null, 'GI', 'Gibraltar');
INSERT INTO `apps_countries` VALUES (null, 'GK', 'Guernsey');
INSERT INTO `apps_countries` VALUES (null, 'GR', 'Greece');
INSERT INTO `apps_countries` VALUES (null, 'GL', 'Greenland');
INSERT INTO `apps_countries` VALUES (null, 'GD', 'Grenada');
INSERT INTO `apps_countries` VALUES (null, 'GP', 'Guadeloupe');
INSERT INTO `apps_countries` VALUES (null, 'GU', 'Guam');
INSERT INTO `apps_countries` VALUES (null, 'GT', 'Guatemala');
INSERT INTO `apps_countries` VALUES (null, 'GN', 'Guinea');
INSERT INTO `apps_countries` VALUES (null, 'GW', 'Guinea-Bissau');
INSERT INTO `apps_countries` VALUES (null, 'GY', 'Guyana');
INSERT INTO `apps_countries` VALUES (null, 'HT', 'Haiti');
INSERT INTO `apps_countries` VALUES (null, 'HM', 'Heard and Mc Donald Islands');
INSERT INTO `apps_countries` VALUES (null, 'HN', 'Honduras');
INSERT INTO `apps_countries` VALUES (null, 'HK', 'Hong Kong');
INSERT INTO `apps_countries` VALUES (null, 'HU', 'Hungary');
INSERT INTO `apps_countries` VALUES (null, 'IS', 'Iceland');
INSERT INTO `apps_countries` VALUES (null, 'IN', 'India');
INSERT INTO `apps_countries` VALUES (null, 'IM', 'Isle of Man');
INSERT INTO `apps_countries` VALUES (null, 'ID', 'Indonesia');
INSERT INTO `apps_countries` VALUES (null, 'IR', 'Iran (Islamic Republic of)');
INSERT INTO `apps_countries` VALUES (null, 'IQ', 'Iraq');
INSERT INTO `apps_countries` VALUES (null, 'IE', 'Ireland');
INSERT INTO `apps_countries` VALUES (null, 'IL', 'Israel');
INSERT INTO `apps_countries` VALUES (null, 'IT', 'Italy');
INSERT INTO `apps_countries` VALUES (null, 'CI', 'Ivory Coast');
INSERT INTO `apps_countries` VALUES (null, 'JE', 'Jersey');
INSERT INTO `apps_countries` VALUES (null, 'JM', 'Jamaica');
INSERT INTO `apps_countries` VALUES (null, 'JP', 'Japan');
INSERT INTO `apps_countries` VALUES (null, 'JO', 'Jordan');
INSERT INTO `apps_countries` VALUES (null, 'KZ', 'Kazakhstan');
INSERT INTO `apps_countries` VALUES (null, 'KE', 'Kenya');
INSERT INTO `apps_countries` VALUES (null, 'KI', 'Kiribati');
INSERT INTO `apps_countries` VALUES (null, 'KP', 'Korea, Democratic People''s Republic of');
INSERT INTO `apps_countries` VALUES (null, 'KR', 'Korea, Republic of');
INSERT INTO `apps_countries` VALUES (null, 'XK', 'Kosovo');
INSERT INTO `apps_countries` VALUES (null, 'KW', 'Kuwait');
INSERT INTO `apps_countries` VALUES (null, 'KG', 'Kyrgyzstan');
INSERT INTO `apps_countries` VALUES (null, 'LA', 'Lao People''s Democratic Republic');
INSERT INTO `apps_countries` VALUES (null, 'LV', 'Latvia');
INSERT INTO `apps_countries` VALUES (null, 'LB', 'Lebanon');
INSERT INTO `apps_countries` VALUES (null, 'LS', 'Lesotho');
INSERT INTO `apps_countries` VALUES (null, 'LR', 'Liberia');
INSERT INTO `apps_countries` VALUES (null, 'LY', 'Libyan Arab Jamahiriya');
INSERT INTO `apps_countries` VALUES (null, 'LI', 'Liechtenstein');
INSERT INTO `apps_countries` VALUES (null, 'LT', 'Lithuania');
INSERT INTO `apps_countries` VALUES (null, 'LU', 'Luxembourg');
INSERT INTO `apps_countries` VALUES (null, 'MO', 'Macau');
INSERT INTO `apps_countries` VALUES (null, 'MK', 'Macedonia');
INSERT INTO `apps_countries` VALUES (null, 'MG', 'Madagascar');
INSERT INTO `apps_countries` VALUES (null, 'MW', 'Malawi');
INSERT INTO `apps_countries` VALUES (null, 'MY', 'Malaysia');
INSERT INTO `apps_countries` VALUES (null, 'MV', 'Maldives');
INSERT INTO `apps_countries` VALUES (null, 'ML', 'Mali');
INSERT INTO `apps_countries` VALUES (null, 'MT', 'Malta');
INSERT INTO `apps_countries` VALUES (null, 'MH', 'Marshall Islands');
INSERT INTO `apps_countries` VALUES (null, 'MQ', 'Martinique');
INSERT INTO `apps_countries` VALUES (null, 'MR', 'Mauritania');
INSERT INTO `apps_countries` VALUES (null, 'MU', 'Mauritius');
INSERT INTO `apps_countries` VALUES (null, 'TY', 'Mayotte');
INSERT INTO `apps_countries` VALUES (null, 'MX', 'Mexico');
INSERT INTO `apps_countries` VALUES (null, 'FM', 'Micronesia, Federated States of');
INSERT INTO `apps_countries` VALUES (null, 'MD', 'Moldova, Republic of');
INSERT INTO `apps_countries` VALUES (null, 'MC', 'Monaco');
INSERT INTO `apps_countries` VALUES (null, 'MN', 'Mongolia');
INSERT INTO `apps_countries` VALUES (null, 'ME', 'Montenegro');
INSERT INTO `apps_countries` VALUES (null, 'MS', 'Montserrat');
INSERT INTO `apps_countries` VALUES (null, 'MA', 'Morocco');
INSERT INTO `apps_countries` VALUES (null, 'MZ', 'Mozambique');
INSERT INTO `apps_countries` VALUES (null, 'MM', 'Myanmar');
INSERT INTO `apps_countries` VALUES (null, 'NA', 'Namibia');
INSERT INTO `apps_countries` VALUES (null, 'NR', 'Nauru');
INSERT INTO `apps_countries` VALUES (null, 'NP', 'Nepal');
INSERT INTO `apps_countries` VALUES (null, 'NL', 'Netherlands');
INSERT INTO `apps_countries` VALUES (null, 'AN', 'Netherlands Antilles');
INSERT INTO `apps_countries` VALUES (null, 'NC', 'New Caledonia');
INSERT INTO `apps_countries` VALUES (null, 'NZ', 'New Zealand');
INSERT INTO `apps_countries` VALUES (null, 'NI', 'Nicaragua');
INSERT INTO `apps_countries` VALUES (null, 'NE', 'Niger');
INSERT INTO `apps_countries` VALUES (null, 'NG', 'Nigeria');
INSERT INTO `apps_countries` VALUES (null, 'NU', 'Niue');
INSERT INTO `apps_countries` VALUES (null, 'NF', 'Norfolk Island');
INSERT INTO `apps_countries` VALUES (null, 'MP', 'Northern Mariana Islands');
INSERT INTO `apps_countries` VALUES (null, 'NO', 'Norway');
INSERT INTO `apps_countries` VALUES (null, 'OM', 'Oman');
INSERT INTO `apps_countries` VALUES (null, 'PK', 'Pakistan');
INSERT INTO `apps_countries` VALUES (null, 'PW', 'Palau');
INSERT INTO `apps_countries` VALUES (null, 'PS', 'Palestine');
INSERT INTO `apps_countries` VALUES (null, 'PA', 'Panama');
INSERT INTO `apps_countries` VALUES (null, 'PG', 'Papua New Guinea');
INSERT INTO `apps_countries` VALUES (null, 'PY', 'Paraguay');
INSERT INTO `apps_countries` VALUES (null, 'PE', 'Peru');
INSERT INTO `apps_countries` VALUES (null, 'PH', 'Philippines');
INSERT INTO `apps_countries` VALUES (null, 'PN', 'Pitcairn');
INSERT INTO `apps_countries` VALUES (null, 'PL', 'Poland');
INSERT INTO `apps_countries` VALUES (null, 'PT', 'Portugal');
INSERT INTO `apps_countries` VALUES (null, 'PR', 'Puerto Rico');
INSERT INTO `apps_countries` VALUES (null, 'QA', 'Qatar');
INSERT INTO `apps_countries` VALUES (null, 'RE', 'Reunion');
INSERT INTO `apps_countries` VALUES (null, 'RO', 'Romania');
INSERT INTO `apps_countries` VALUES (null, 'RU', 'Russian Federation');
INSERT INTO `apps_countries` VALUES (null, 'RW', 'Rwanda');
INSERT INTO `apps_countries` VALUES (null, 'KN', 'Saint Kitts and Nevis');
INSERT INTO `apps_countries` VALUES (null, 'LC', 'Saint Lucia');
INSERT INTO `apps_countries` VALUES (null, 'VC', 'Saint Vincent and the Grenadines');
INSERT INTO `apps_countries` VALUES (null, 'WS', 'Samoa');
INSERT INTO `apps_countries` VALUES (null, 'SM', 'San Marino');
INSERT INTO `apps_countries` VALUES (null, 'ST', 'Sao Tome and Principe');
INSERT INTO `apps_countries` VALUES (null, 'SA', 'Saudi Arabia');
INSERT INTO `apps_countries` VALUES (null, 'SN', 'Senegal');
INSERT INTO `apps_countries` VALUES (null, 'RS', 'Serbia');
INSERT INTO `apps_countries` VALUES (null, 'SC', 'Seychelles');
INSERT INTO `apps_countries` VALUES (null, 'SL', 'Sierra Leone');
INSERT INTO `apps_countries` VALUES (null, 'SG', 'Singapore');
INSERT INTO `apps_countries` VALUES (null, 'SK', 'Slovakia');
INSERT INTO `apps_countries` VALUES (null, 'SI', 'Slovenia');
INSERT INTO `apps_countries` VALUES (null, 'SB', 'Solomon Islands');
INSERT INTO `apps_countries` VALUES (null, 'SO', 'Somalia');
INSERT INTO `apps_countries` VALUES (null, 'ZA', 'South Africa');
INSERT INTO `apps_countries` VALUES (null, 'GS', 'South Georgia South Sandwich Islands');
INSERT INTO `apps_countries` VALUES (null, 'ES', 'Spain');
INSERT INTO `apps_countries` VALUES (null, 'LK', 'Sri Lanka');
INSERT INTO `apps_countries` VALUES (null, 'SH', 'St. Helena');
INSERT INTO `apps_countries` VALUES (null, 'PM', 'St. Pierre and Miquelon');
INSERT INTO `apps_countries` VALUES (null, 'SD', 'Sudan');
INSERT INTO `apps_countries` VALUES (null, 'SR', 'Suriname');
INSERT INTO `apps_countries` VALUES (null, 'SJ', 'Svalbard and Jan Mayen Islands');
INSERT INTO `apps_countries` VALUES (null, 'SZ', 'Swaziland');
INSERT INTO `apps_countries` VALUES (null, 'SE', 'Sweden');
INSERT INTO `apps_countries` VALUES (null, 'CH', 'Switzerland');
INSERT INTO `apps_countries` VALUES (null, 'SY', 'Syrian Arab Republic');
INSERT INTO `apps_countries` VALUES (null, 'TW', 'Taiwan');
INSERT INTO `apps_countries` VALUES (null, 'TJ', 'Tajikistan');
INSERT INTO `apps_countries` VALUES (null, 'TZ', 'Tanzania, United Republic of');
INSERT INTO `apps_countries` VALUES (null, 'TH', 'Thailand');
INSERT INTO `apps_countries` VALUES (null, 'TG', 'Togo');
INSERT INTO `apps_countries` VALUES (null, 'TK', 'Tokelau');
INSERT INTO `apps_countries` VALUES (null, 'TO', 'Tonga');
INSERT INTO `apps_countries` VALUES (null, 'TT', 'Trinidad and Tobago');
INSERT INTO `apps_countries` VALUES (null, 'TN', 'Tunisia');
INSERT INTO `apps_countries` VALUES (null, 'TR', 'Turkey');
INSERT INTO `apps_countries` VALUES (null, 'TM', 'Turkmenistan');
INSERT INTO `apps_countries` VALUES (null, 'TC', 'Turks and Caicos Islands');
INSERT INTO `apps_countries` VALUES (null, 'TV', 'Tuvalu');
INSERT INTO `apps_countries` VALUES (null, 'UG', 'Uganda');
INSERT INTO `apps_countries` VALUES (null, 'UA', 'Ukraine');
INSERT INTO `apps_countries` VALUES (null, 'AE', 'United Arab Emirates');
INSERT INTO `apps_countries` VALUES (null, 'GB', 'United Kingdom');
INSERT INTO `apps_countries` VALUES (null, 'US', 'United States');
INSERT INTO `apps_countries` VALUES (null, 'UM', 'United States minor outlying islands');
INSERT INTO `apps_countries` VALUES (null, 'UY', 'Uruguay');
INSERT INTO `apps_countries` VALUES (null, 'UZ', 'Uzbekistan');
INSERT INTO `apps_countries` VALUES (null, 'VU', 'Vanuatu');
INSERT INTO `apps_countries` VALUES (null, 'VA', 'Vatican City State');
INSERT INTO `apps_countries` VALUES (null, 'VE', 'Venezuela');
INSERT INTO `apps_countries` VALUES (null, 'VN', 'Vietnam');
INSERT INTO `apps_countries` VALUES (null, 'VG', 'Virgin Islands (British)');
INSERT INTO `apps_countries` VALUES (null, 'VI', 'Virgin Islands (U.S.)');
INSERT INTO `apps_countries` VALUES (null, 'WF', 'Wallis and Futuna Islands');
INSERT INTO `apps_countries` VALUES (null, 'EH', 'Western Sahara');
INSERT INTO `apps_countries` VALUES (null, 'YE', 'Yemen');
INSERT INTO `apps_countries` VALUES (null, 'YU', 'Yugoslavia');
INSERT INTO `apps_countries` VALUES (null, 'ZR', 'Zaire');
INSERT INTO `apps_countries` VALUES (null, 'ZM', 'Zambia');
INSERT INTO `apps_countries` VALUES (null, 'ZW', 'Zimbabwe');



##Create Domain Table
Create table `pandadoc_domains` (domain varchar(64), name varchar(64), description text, location varchar(2083), employees int, url varchar(2083), raised_text varchar(64), raised int , linkedin varchar(2083), crunchbase varchar(2083), twitter varchar(2083), facebook varchar(2083), push char(1), last_updated datetime, industry varchar(64), created_at datetime, index(domain, location, employees, industry), primary key(domain));
SET autocommit=0;
LOAD DATA LOCAL INFILE '/Users/austin.lee/Desktop/memsql/panda_doc_analysis/pandadoc_domains.csv'
INTO TABLE test_instance.pandadoc_domains
FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(domain, name, description, location, employees, url, raised_text, raised, linkedin, crunchbase, twitter, facebook, push, last_updated, industry, created_at);
COMMIT;




