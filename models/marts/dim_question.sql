with questions as (
    select * from {{ ref('stg_stackoverflow_posts_questions') }}
),

final as (
    select
        question_id,
        title,
        body_length,
        title_length,
        has_been_edited,
        tag_count,
        has_accepted_answer,
        creation_date,
        last_activity_date,
        last_edit_date,
        owner_user_id,
        accepted_answer_id,
        tags_group_id
    from questions
)

select * from final
