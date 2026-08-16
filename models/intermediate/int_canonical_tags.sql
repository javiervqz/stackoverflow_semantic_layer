{{
    config(
        materialized='view',
        incremental_strategy='merge',
        unique_key='raw_tags'
    )
}}

with distinct_raw_tags as (
    select
        tags as raw_tags,
        max(creation_date) as creation_date,
        max(last_edit_date) as last_edit_date
    from {{ ref('stg_stackoverflow_posts_questions') }}
    where tags is not null
    {% if is_incremental() %}
    and (
        creation_date >= (
            select timestamp_add(max(creation_date), interval {{ var('incremental_lookback_days') }} day)
            from {{ this }}
        )
        or last_edit_date >= (
            select timestamp_add(max(last_edit_date), interval {{ var('incremental_lookback_days') }} day)
            from {{ this }}
        )
    )
    {% endif %}
    group by tags
),

canonical_tags as (
    select
        distinct_raw_tags.raw_tags,
        distinct_raw_tags.creation_date,
        distinct_raw_tags.last_edit_date,
        (
            select array_to_string(array_agg(tag order by tag), '|')
            from unnest(split(distinct_raw_tags.raw_tags, '|')) as tag
            where tag != ''
        ) as canonical_tags_group
    from distinct_raw_tags
),

final as (
    select
        raw_tags,
        canonical_tags_group as tags_group,
        canonical_tags_group as tag_combination,
        {{ dbt_utils.generate_surrogate_key(['canonical_tags_group']) }} as tags_group_id,
        creation_date,
        last_edit_date
    from canonical_tags
)

select * from final
