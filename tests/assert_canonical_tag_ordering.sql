-- Acceptance Test: Canonical tag group strings in int_canonical_tags must be strictly sorted alphabetically and contain no empty components or trailing pipes
with parsed as (
    select
        raw_tags,
        tags_group,
        (
            select array_to_string(array_agg(tag order by tag), '|')
            from unnest(split(tags_group, '|')) as tag
            where tag != ''
        ) as reordered_tags_group
    from {{ ref('int_canonical_tags') }}
)
select
    raw_tags,
    tags_group,
    reordered_tags_group
from parsed
where tags_group != reordered_tags_group
   or tags_group like '|%'
   or tags_group like '%|'
