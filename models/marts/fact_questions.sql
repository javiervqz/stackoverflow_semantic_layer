with source as (

    select * from {{ ref('stg_stackoverflow_posts_questions') }}

),

renamed as (

    select
        question_id,
        --FK
        tags_group_id,
        accepted_answer_id,
        owner_user_id,

        --attributes
        title,
        has_accepted_answer,
        --timestamp
        creation_date,
        favorite_count,
        last_activity_date,
        last_edit_date,
        --facts
        score,
        view_count
        answer_count,
        comment_count,

    from source

)

select * from renamed
