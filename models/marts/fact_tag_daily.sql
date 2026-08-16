{{
    config(
        materialized='view'
    )
}}

with questions as (
    select * from {{ ref('stg_stackoverflow_posts_questions') }}
),

tags as (
    select * from {{ ref('stg_stackoverflow_tags') }}
),

unnested_tags as (
    select
        question_id,
        cast(date(creation_date) as timestamp) as date_day,
        accepted_answer_id,
        answer_count,
        view_count,
        comment_count,
        score,
        favorite_count,
        tag_name
    from questions,
    unnest(split(tags, '|')) as tag_name
),

daily_agg as (
    select
        tag_name,
        date_day,
        count(distinct question_id) as total_questions,
        sum(answer_count) as total_answers,
        countif(accepted_answer_id is not null) as questions_with_accepted_answer,
        countif(answer_count > 0) as questions_with_answers,
        sum(view_count) as total_views,
        sum(comment_count) as total_comments,
        sum(score) as total_score,
        sum(favorite_count) as total_favorites
    from unnested_tags
    group by 1, 2
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['daily_agg.tag_name', 'cast(daily_agg.date_day as string)']) }} as tag_daily_id,
        tags.tag_id,
        daily_agg.tag_name,
        daily_agg.date_day,
        daily_agg.total_questions,
        daily_agg.total_answers,
        daily_agg.questions_with_accepted_answer,
        daily_agg.questions_with_answers,
        daily_agg.total_views,
        daily_agg.total_comments,
        daily_agg.total_score,
        daily_agg.total_favorites
    from daily_agg
    left join tags on daily_agg.tag_name = tags.tag_name
)

select * from final
