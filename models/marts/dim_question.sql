with questions as (
    select * from {{ ref('stg_stackoverflow_posts_questions') }}
),

canonical_tags as (
    select
        q.*,
        (
            select array_to_string(array_agg(tag order by tag), '|')
            from unnest(split(q.tags, '|')) as tag
            where tag != ''
        ) as canonical_tags_group
    from questions q
),

final as (
    select
        question_id,
        title,
        body_length,
        title_length,
        has_been_edited,
        tag_count,
        canonical_tags_group as tags_group,
        canonical_tags_group as tag_combination,
        {{ dbt_utils.generate_surrogate_key(['canonical_tags_group']) }} as tags_group_id,
        count(*) over (partition by canonical_tags_group) as tag_combination_volume,
        has_accepted_answer,
        creation_date,
        last_activity_date,
        last_edit_date,
        owner_user_id,
        accepted_answer_id
    from canonical_tags
)

select * from final
