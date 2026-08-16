{{
    config(
        materialized='view',
        incremental_strategy='merge',
        unique_key='question_id'
    )
}}

with questions as (
    select * from {{ ref('stg_stackoverflow_posts_questions') }}
    {% if is_incremental() %}
    where creation_date >= (
        select timestamp_add(max(creation_date), interval {{ var('incremental_lookback_days') }} day)
        from {{ this }}
    )
    or last_edit_date >= (
        select timestamp_add(max(last_edit_date), interval {{ var('incremental_lookback_days') }} day)
        from {{ this }}
    )
    {% endif %}
),

canonical_tags as (
    select * from {{ ref('int_canonical_tags') }}
),

final as (
    select
        questions.question_id,
        questions.title,
        questions.body_length,
        questions.title_length,
        questions.has_been_edited,
        questions.tag_count,
        canonical_tags.tags_group,
        canonical_tags.tag_combination,
        canonical_tags.tags_group_id,
        count(*) over (partition by canonical_tags.tags_group) as tag_combination_volume,
        questions.has_accepted_answer,
        questions.creation_date,
        questions.last_activity_date,
        questions.last_edit_date,
        questions.owner_user_id,
        questions.accepted_answer_id
    from questions
    left join canonical_tags
        on questions.tags = canonical_tags.raw_tags
)

select * from final
