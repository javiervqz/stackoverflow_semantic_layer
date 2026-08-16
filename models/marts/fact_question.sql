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
    {% endif %}
),

final as (
    select
        question_id,
        creation_date,
        accepted_answer_id,
        score,
        view_count,
        answer_count,
        comment_count,
        favorite_count
    from questions
)

select * from final
