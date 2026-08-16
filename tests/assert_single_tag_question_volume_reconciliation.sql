-- Acceptance Test: Total questions for any tag across all days in fact_tag_daily must equal or exceed single-tag questions in dim_question
with dim_single_tags as (
    select
        tags_group as tag_name,
        count(*) as dim_questions_count
    from {{ ref('dim_question') }}
    where tag_count = 1
    group by 1
),
mart_single_tags as (
    select
        tag_name,
        sum(total_questions) as mart_questions_count
    from {{ ref('fact_tag_daily') }}
    group by 1
)
select
    d.tag_name,
    d.dim_questions_count,
    m.mart_questions_count
from dim_single_tags d
inner join mart_single_tags m
    on d.tag_name = m.tag_name
where m.mart_questions_count < d.dim_questions_count
