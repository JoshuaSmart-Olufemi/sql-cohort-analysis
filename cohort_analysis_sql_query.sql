-------- primary, base cte with the entire table
with base_cte_1 as (
    select *
    from challenge.public.events 
    )
------- second cte pulling out metrics (cohort_month, count_of_events and day_when_event_occured_in_month) to be used for deriving standard cohorts
, count_of_events_and_days_when_event_occured_in_month_2 as (
    select 
    date_trunc('month', collector_tstamp) as cohort_month
    , count(distinct collector_tstamp)::integer as count_of_events
    , user_id
    , date_trunc('day', collector_tstamp) as day_when_event_occured_in_month
    from base_cte_1
    group by 1,3,4 
    )
 -------- third cte to filter the count_of_events greater than zero and to create the count_of_days_where_event to generate the standard cohort
, count_of_days_where_event_3 as (
    
    select 
    cohort_month
    , user_id
    , count(day_when_event_occured_in_month) as count_of_days_where_event
    from count_of_events_and_days_when_event_occured_in_month_2
    where count_of_events > 0
    group by 1,2
    )
------- fourth cte to create the standard cohorts
, standard_cohorts_4 as (
    select *,
    case when count_of_days_where_event < 4 then 'infrequent' 
    when count_of_days_where_event > 3 and count_of_days_where_event < 8 then 'frequent'
    when count_of_days_where_event > 7 then 'power_user' 
    end as standard_cohorts
        
    , min(cohort_month) over (partition by user_id) as first_event_month
    , max(cohort_month) over (partition by user_id) as last_event_month
    , lag(cohort_month) over (partition by user_id order by cohort_month) as month_before
    , lead(cohort_month) over (partition by user_id order by cohort_month) as month_after_current_month
    
    from count_of_days_where_event_3
    )
----- fifth cte to create the special virtual cohorts
, special_cohorts_5 as (
    
    select cohort_month, user_id, count_of_days_where_event, standard_cohorts, first_event_month, month_before,
    
    case when date_trunc('month',month_before) is not null and date_trunc('month', cohort_month) is null and date_trunc('month',month_after_current_month) is not null or null then 'zombie'
    
         when date_trunc('month', first_event_month) = date_trunc('month', cohort_month) then 'new'
    
         when date_trunc('month', first_event_month) < date_trunc('month', cohort_month) and date_trunc('month', last_event_month) = date_trunc('month', cohort_month) then 'reacquired'
    
    end as special_virtual_cohorts
    from standard_cohorts_4

    )
    
-------- a sixth cte to union the standard_cohort column and special_virtual_cohorts column together creating one column containing both fields named: this_month_status
, union_for_cohorts_6 as (
        
    select user_id, standard_cohorts as this_month_status from special_cohorts_5 
    union 
    select user_id, special_virtual_cohorts from special_cohorts_5
       
    )
    
  ---- a seventh cte to perform data cleaning for "this_month" date field and window function for "last_month_status" field 
, columns_for_final_table_7 as (
    
    select concat(date_part('year',cohort_month),'-',date_part('month',cohort_month)) as this_month, this_month_status
     , lag(this_month_status) over (partition by this_month order by this_month) as last_month_status
    from special_cohorts_5 as a
    left join 
    union_for_cohorts_6 as b 
    on a.user_id = b.user_id
    )
---- a final cte with all the relevant fields (4) for results set
, final as (
    select 
    this_month
    , this_month_status
    , last_month_status
    , count(1) as transitions 
    from columns_for_final_table_7
    where this_month_status != last_month_status
    group by 1,2,3
    )
    
select * from final  
    