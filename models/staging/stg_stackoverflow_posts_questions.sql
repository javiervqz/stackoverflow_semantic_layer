with source as (

    select * from {{ source('stackoverflow', 'posts_questions') }}

),

renamed as (

    select
        id as question_id,
        title,
        body,
        accepted_answer_id,
        if(accepted_answer_id is null, false, true) as has_accepted_answer,
        answer_count,
        comment_count,
        creation_date,
        favorite_count,
        last_activity_date,
        last_edit_date,
        owner_user_id,
        score,
        tags,
        {{ dbt_utils.generate_surrogate_key(['tags']) }} as tags_group_id,
        view_count,
        length(body) as body_length,
        length(title) as title_length,
        last_edit_date is not null as has_been_edited,
        array_length(split(tags, '|')) as tag_count

    from source

)

select * from renamed
