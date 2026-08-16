with source as (

    select * from {{ source('stackoverflow', 'posts_answers') }}

),

renamed as (

    select
        id as answer_id,
        body,
        comment_count,
        creation_date,
        last_activity_date,
        last_edit_date,
        owner_user_id,
        parent_id as question_id,
        score

    from source

)

select * from renamed
