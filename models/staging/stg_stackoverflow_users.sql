with source as (

    select * from {{ source('stackoverflow', 'users') }}

),

renamed as (

    select
        id as user_id,
        display_name,
        reputation,
        creation_date,
        last_access_date,
        location,
        about_me,
        views as profile_views,
        up_votes,
        down_votes

    from source

)

select * from renamed
