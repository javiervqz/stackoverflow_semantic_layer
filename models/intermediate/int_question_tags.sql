with questions as (

    select * from {{ ref('stg_stackoverflow_posts_questions') }}

),

tags as (

    select * from {{ ref('stg_stackoverflow_tags') }}

),

unnested_tags as (

    select distinct
        tags_group_id,
        tag
    from questions,
        unnest(split(tags, '|')) as tag

),

filtered_tags as (

    select
        tags_group_id,
        tag
    from unnested_tags
    where tag is not null and tag != ''

),

joined as (

    select
        filtered_tags.tags_group_id,
        tags.tag_id,
        filtered_tags.tag

    from filtered_tags
    inner join tags
        on filtered_tags.tag = tags.tag_name

)

select * from joined