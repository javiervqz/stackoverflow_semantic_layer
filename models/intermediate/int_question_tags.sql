    {# meant as incremental, but that costs more in bq #}
{{
    config(
        materialized='table',
        incremental_strategy='merge',
        unique_key=['tag_group_id', 'tag_id']
    )
}}

with questions as (

    select * from {{ ref('stg_stackoverflow_posts_questions') }}
    {% if is_incremental() %}
    where creation_date >= (
        select timestamp_add(max(created_date), interval {{ var('incremental_lookback_days') }} day)
        from {{ this }}
    )
    {% endif %}

),

tags as (

    select * from {{ ref('stg_stackoverflow_tags') }}

),

unnested_tags as (

    select
        tags_group_id,
        tag,
        max(array_length(split(tags, '|'))) as count_tags,
        min(creation_date) as created_date
    from questions,
        unnest(split(tags, '|')) as tag
    group by 1, 2

),

filtered_tags as (

    select
        tags_group_id,
        tag,
        count_tags,
        created_date
    from unnested_tags
    where tag is not null and tag != ''

),

joined as (

    select
        filtered_tags.tags_group_id,
        tags.tag_id,
        filtered_tags.count_tags,
        filtered_tags.tag,
        filtered_tags.created_date

    from filtered_tags
    inner join tags
        on filtered_tags.tag = tags.tag_name

)

select * from joined