### Chartio Analysis

  
Select id.user_id
	,min(time_stamp)
    ,company_trial_end
    ,company_org_status
from chartio.identify id
inner join (select user_id from chartio.identify where company_org_status = 'trialing' group by user_id) trial
	on trial.user_id = id.user_id
where time_stamp > company_trial_end
group by id.user_id, company_org_status,company_trial_end;






##Trialing Events (2,426)
select event_type from (
select event_type
	, sum(count_companies) as count_companies
	, sum(case when converted = 1 then count_companies end)/sum(count_companies)*1.00 as conversion_rate
from (
	select ev.event_id, concat(event_category," ", event_name) as event_type, case when converted.user_id is not null then 1 else 0 end as converted
		, count(distinct track.user_id) as count_users
		, count(distinct track.organization_id) as count_companies
	from chartio.track track
	inner join trialing_users trial
		on trial.user_id = track.user_id
	left join converted_users converted on track.user_id = converted.user_id
	inner join chartio.event_types ev on ev.event_name = track.properties_name and ev.event_category = track.properties_category and track.properties_details not like '%Chartio Demo%'
	group by 1,2,3
) aaa
where event_type not in ('team delete', 'billing invoice-export')
group by 1
having count_companies > 5
) aaa;

##Self -service vs. sales signup
select * from chartio.track where properties_category = 'team' and properties_name = 'delete';

select * from chartio.company;

##List of company/events/long

select co.company_name
    , co.company_signup_type
    , co.company_feature_set
	, concat(event_category," ", event_name) as event_type
    , case when converted.user_id is not null then 1 else 0 end as converted
	, count(distinct track.user_id) as count_users
	, count(distinct track.time_stamp) as count_events
from chartio.track track
inner join trialing_users trial
	on trial.user_id = track.user_id
left join converted_users converted on track.user_id = converted.user_id
inner join chartio.event_types ev on ev.event_name = track.properties_name and ev.event_category = track.properties_category and track.properties_details not like '%Chartio Demo%'
inner join chartio.company co on co.company_id = track.organization_id and track.time_stamp <= company_trial_end
where concat(event_category," ", event_name) 
	in ('chart create',
	'chart delete',
	'dashboard archive',
	'dashboard clone',
	'dashboard Created',
	'dashboard export',
	'dashboard trash',
	'dashboard Updated',
	'datasource connect',
	'datasource create',
	'datasource disconnect',
	'datasource update',
	'team create',
	'user create',
	'user delete',
	'user email',
	'user join')
		and company_name is not null
        and from_unixtime(track.time_stamp) <= '2016-06-02'
group by 1,2,3,4,5;


###GOLDEN EVENT: 'team delete'
###Obvious events: billing invoice-export

select * from chartio.converted_users;
select from_unixtime(time_stamp) from chartio.track order by time_stamp desc;
select * from chartio.trialing_users;
## Long list of events/current leads for sample:


select co.company_name
    , co.company_signup_type
    , co.company_feature_set
	, concat(event_category," ", event_name) as event_type
    , max(case when converted.user_id is not null then 1 else 0 end) as converted
    , max(from_unixtime(end_dates.company_trial_end)) as trial_end_date
	, count(distinct track.user_id) as count_users
	, count(distinct track.time_stamp) as count_events
from chartio.track track
inner join trialing_users trial
	on trial.user_id = track.user_id
left join converted_users converted on track.user_id = converted.user_id
left join (select user_id, company_trial_end from chartio.identify group by 1,2) end_dates on track.user_id = end_dates.user_id
inner join chartio.event_types ev on ev.event_name = track.properties_name and ev.event_category = track.properties_category and track.properties_details not like '%Chartio Demo%'
left join chartio.company co on co.company_id = track.organization_id
where from_unixtime(track.time_stamp) >= '2016-09-02' 
	and concat(event_category," ", event_name) 
	in ('chart create',
	'chart delete',
	'dashboard archive',
	'dashboard clone',
	'dashboard Created',
	'dashboard export',
	'dashboard trash',
	'dashboard Updated',
	'datasource connect',
	'datasource create',
	'datasource disconnect',
	'datasource update',
	'team create',
	'user create',
	'user delete',
	'user email',
	'user join')
		and company_name is not null
group by 1,2,3,4
having max(from_unixtime(end_dates.company_trial_end)) >= '2016-09-15';


SELECT 
    email,
    company_signup_type,
    company_name,
    MAX(company_org_status),
    MAX(FROM_UNIXTIME(company_trial_end)) AS trial_ending
FROM
    chartio.identify
WHERE
    company_name IN ('Rubilect' , 'hijob GmbH', 'eMeals', 'Lynks')
GROUP BY 1 , 2 , 3;
select * from chartio.track;

##Event Training Dataset

select co.company_name
    , co.company_signup_type
    , co.company_feature_set
	, concat(event_category," ", event_name) as event_type	
    , max( domain.industry) as industry
    , max( domain.employees) as count_employees
    , max(case when converted.user_id is not null then 1 else 0 end) as converted    
	, count(distinct track.user_id) as count_users
	, count(distinct track.time_stamp) as count_events
from chartio.company co
inner join chartio.track track on 
	track.organization_id = co.company_id  and track.time_stamp <= co.company_trial_end and track.time_stamp >= co.company_trial_start
left join converted_users converted on co.company_id = converted.company_id
left join (select email.email
			, domain.industry
            , domain.employees
            from chartio.emails email
            inner join chartio.domains domain on domain.domain = email.domain
            group by 1,2,3) domain
		on domain.email = track.user_id
inner join chartio.event_types ev on ev.event_name = track.properties_name and ev.event_category = track.properties_category and track.properties_details not like '%Chartio Demo%'
where from_unixtime(track.time_stamp) >= '2016-06-02'
group by 1,2,3,4;

