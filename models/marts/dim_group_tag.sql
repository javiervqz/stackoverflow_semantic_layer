with source as (
    select * from {{ ref('int_question_tags') }}
),
renamed as (
    select 
        tags_group_id,
        tag_id,
        count_tags,
        tag,
        created_date
    from source 
)
select * from renamed