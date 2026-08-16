with source as (
    select * from {{ ref('stg_stackoverflow_tags') }}
),

renamed as (
    select 
        tag_id,
        tag_name,
        questions_count as tag_volume,
        excerpt_post_id,
        wiki_post_id
    from source 
)

select * from renamed
