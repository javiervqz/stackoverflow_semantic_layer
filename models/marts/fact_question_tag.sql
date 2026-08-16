with questions as (
    select * from {{ ref('stg_stackoverflow_posts_questions') }}
),

tags as (
    select * from {{ ref('stg_stackoverflow_tags') }}
),

unnested_tags as (
    select
        question_id,
        tag_name
    from questions,
    unnest(split(tags, '|')) as tag_name
    where tag_name != ''
),

final as (
    select
        u.question_id,
        t.tag_id,
        u.tag_name
    from unnested_tags u
    left join tags t on u.tag_name = t.tag_name
)

select * from final
