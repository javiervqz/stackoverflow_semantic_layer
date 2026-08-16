with source as (
    select * from {{ ref('stg_stackoverflow_tags') }}
),

renamed as (
    select 
        tag_id,
        excerpt_post_id,
        wiki_post_id,
        tag_name

    from source 
)

select * from renamed
