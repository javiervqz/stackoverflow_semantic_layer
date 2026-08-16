with days as (
    select
        cast(date_day as date) as date_day
    from unnest(generate_date_array('2008-01-01', date_add(current_date(), interval 1 year), interval 1 day)) as date_day
)

select * from days
