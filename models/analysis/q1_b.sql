{# How about combinations of tags? Which tag combinations lead to the most answers
and the highest rate of accepted answers for the current year? #}

with tag_combinations as (
    select
        tags_group_id,
        string_agg(tag, '|' order by tag) as tag_combination,
        max(count_tags) as count_tags
    from {{ ref('dim_group_tag') }}
    group by tags_group_id
),

agg as (
    select
        tc.tag_combination,
        tc.count_tags,
        count(distinct questions.question_id) as count_questions,
        countif(questions.has_accepted_answer) as questions_with_accepted,
        countif(not questions.has_accepted_answer) as questions_without_accepted,
        safe_divide(countif(questions.has_accepted_answer), count(distinct questions.question_id)) as acceptance_rate
    from {{ ref('fact_questions') }} as questions
    inner join tag_combinations as tc
        on questions.tags_group_id = tc.tags_group_id
    -- where extract(year from questions.creation_date) = extract(year from current_date())
    group by all
)

select * from agg
where count_questions > 1000
order by acceptance_rate desc
