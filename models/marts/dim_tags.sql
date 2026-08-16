with source as (
    select * from {{ ref('stg_stackoverflow_tags') }}
),
renamed as (
    select 
        tag_id,
        tag_name,
        tag_count,
    from source 
)
select * from renamed