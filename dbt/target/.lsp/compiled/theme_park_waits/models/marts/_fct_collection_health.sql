with poll_events as (
    select
        park_id,
        poll_slot,
        case when status = 'success' then 1 else 0 end as successful_attempts,
        case when status = 'failed' then 1 else 0 end as failed_attempts,
        case when status = 'skipped' then 1 else 0 end as skipped_attempts,
        0 as has_snapshot
    from DENG_ACCELERATOR.TABLES._stg_poll_attempts

    union all

    select
        park_id,
        poll_slot,
        0 as successful_attempts,
        0 as failed_attempts,
        0 as skipped_attempts,
        1 as has_snapshot
    from DENG_ACCELERATOR.TABLES._stg_snapshots
),

poll_slots as (
    select
        park_id,
        poll_slot,
        to_timestamp_ntz(poll_slot * 300, 0)::date as collection_date_utc,
        sum(successful_attempts) as successful_attempts,
        sum(failed_attempts) as failed_attempts,
        sum(skipped_attempts) as skipped_attempts,
        max(has_snapshot) as has_snapshot
    from poll_events
    group by park_id, poll_slot
)

select
    park_id,
    collection_date_utc,
    count(*) as recorded_slots,
    sum(has_snapshot) as collected_slots,
    count(*) - sum(has_snapshot) as recorded_slots_without_snapshot,
    sum(successful_attempts) as successful_attempts,
    sum(failed_attempts) as failed_attempts,
    sum(skipped_attempts) as skipped_attempts,
    100.0 * sum(has_snapshot) / count(*) as pct_recorded_slots_collected
from poll_slots
group by park_id, collection_date_utc