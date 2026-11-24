
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from DENG_ACCELERATOR.TABLES._stg_poll_attempts
    group by status

)

select *
from all_values
where value_field not in (
    'success','failed','skipped'
)


