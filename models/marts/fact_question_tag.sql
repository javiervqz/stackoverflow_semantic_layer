{{
    config(
        materialized='view',
        incremental_strategy='merge',
        unique_key='question_tag_id'
    )
}}

with questions as (
    select * from {{ ref('stg_stackoverflow_posts_questions') }}
    {% if is_incremental() %}
    where creation_date >= (
        select timestamp_add(max(creation_date), interval {{ var('incremental_lookback_days') }} day)
        from {{ this }}
    )
    {% endif %}
),

tags as (
    select * from {{ ref('stg_stackoverflow_tags') }}
),

unnested_tags as (
    select
        question_id,
        creation_date,
        tag_count,
        answer_count,
        accepted_answer_id,
        tag_name
    from questions,
    unnest(split(tags, '|')) as tag_name
    where tag_name != ''
),

sorted_tags as (
    select
        question_id,
        creation_date,
        tag_count,
        answer_count,
        accepted_answer_id,
        tag_name
    from unnested_tags
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['s.question_id', 's.tag_name']) }} as question_tag_id,
        s.question_id,
        t.tag_id,
        t.tag_count as tag_lifetime_questions,
        s.tag_name,
        s.creation_date,
        s.tag_count
    from sorted_tags s
    left join tags t on s.tag_name = t.tag_name
)

select * from final
