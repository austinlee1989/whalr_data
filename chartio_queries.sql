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

##Trialing Users (1068)##
create table trialing_users
Select user_id
from chartio.identify id
where id.time_stamp >= company_trial_start and id.time_stamp <= company_trial_end
group by user_id;

##Converted_users- 123
create table converted_users
Select id.user_id
from chartio.identify id
inner join (select company_id from chartio.identify where company_org_status = 'active' group by company_id) active 
	on active.company_id = id.company_id
where id.time_stamp >= company_trial_start and id.time_stamp <= company_trial_end
group by id.user_id;




##Trialing Events (2,426)

select ev.event_id, ev.event_category, ev.event_name
	, count(distinct track.user_id) as count_users, count(distinct track.organization_id) as count_companies
from chartio.track track
inner join (Select user_id
		from chartio.identify id
		where id.time_stamp >= company_trial_start and id.time_stamp <= company_trial_end
        group by user_id) trial
	on trial.user_id = track.user_id;
left join chartio.event_types ev on ev.event_name = track.properties_name and ev.event_category = track.properties_category
group by ev.event_id, ev.event_category, ev.event_name
;

