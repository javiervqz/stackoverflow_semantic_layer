with questions as (
    select * from {{ ref('stg_stackoverflow_posts_questions') }}
),

final as (
    select
        question_id,
        score,
        view_count,
        answer_count,
        comment_count,
        favorite_count
    from questions
)

select * from final
