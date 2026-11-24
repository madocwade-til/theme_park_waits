with health as (
    select
        *,
        count(*) over (
            partition by park_id, collection_date_utc
        ) as rows_per_park_day
    from {{ ref('_fct_daily_collection_health') }}
)

select *
from health
where rows_per_park_day > 1
   or recorded_slots is null
   or collected_slots is null
   or recorded_slots_without_snapshot is null
   or recorded_slots <= 0
   or collected_slots < 0
   or collected_slots > recorded_slots
   or recorded_slots_without_snapshot <> recorded_slots - collected_slots