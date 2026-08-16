{# meant to be an incremental table, but blocked by gcloud #}
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
        accepted_answer_id,
        tag_name
    from questions,
    unnest(split(tags, '|')) as tag_name
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['unnested_tags.question_id', 'tags.tag_id']) }} as question_tag_id,
        unnested_tags.question_id,
        tags.tag_id,
        unnested_tags.tag_name,
        unnested_tags.creation_date,
    from unnested_tags
    left join tags on unnested_tags.tag_name = tags.tag_name
)

select * from final
order by question_id
