{# How about combinations of tags? Which tag combinations lead to the most answers
and the highest rate of accepted answers for the current year? #}

with tag_combinations as (
    select
        question_id,
        string_agg(tag_name, '|' order by tag_name) as tag_combination
    from {{ ref('fact_question_tag') }}
    group by question_id
),

agg as (
    select
        tc.tag_combination,
        dim_questions.tag_count as count_tags,
        count(distinct questions.question_id) as count_questions,
        countif(dim_questions.has_accepted_answer) as questions_with_accepted,
        countif(not dim_questions.has_accepted_answer) as questions_without_accepted,
        safe_divide(countif(dim_questions.has_accepted_answer), count(distinct questions.question_id)) as acceptance_rate
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
    inner join tag_combinations as tc
        on dim_questions.question_id = tc.question_id
    -- where extract(year from dim_questions.creation_date) = extract(year from current_date())
    group by all
)

select * from agg
where count_questions > 1000
order by acceptance_rate desc
