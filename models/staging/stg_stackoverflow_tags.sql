with source as (

    select * from {{ source('stackoverflow', 'tags') }}

),

renamed as (

    select
        id as tag_id,
        tag_name,
        count as questions_count,
        excerpt_post_id,
        wiki_post_id

    from source

)

select * from renamed
