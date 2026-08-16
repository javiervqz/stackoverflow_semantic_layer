{# For posts tagged with only 'python' or 'dbt', what is the year over year change
of the rate of approved answers for the last 10 years? #}

with filtered_questions as (
    select 
        questions.question_id,
        questions.has_accepted_answer,
        extract(year from questions.creation_date) as question_year
    from {{ ref('fact_questions') }} as questions
    inner join {{ ref('dim_group_tag') }} as group_tag
        on questions.tags_group_id = group_tag.tags_group_id
    where group_tag.count_tags = 1
        and group_tag.tag in ('python', 'dbt')
        and extract(year from questions.creation_date) >= extract(year from current_date()) - 9
),

yearly as (
    select
        question_year,
        count(distinct question_id) as total_questions,
        countif(has_accepted_answer) as questions_with_accepted,
        safe_divide(countif(has_accepted_answer), count(distinct question_id)) as acceptance_rate
    from filtered_questions
    group by question_year
)

select
    question_year,
    total_questions,
    questions_with_accepted,
    acceptance_rate,
    lag(acceptance_rate) over (order by question_year) as prev_year_rate,
    acceptance_rate - lag(acceptance_rate) over (order by question_year) as yoy_change,
    safe_divide(
        acceptance_rate - lag(acceptance_rate) over (order by question_year),
        lag(acceptance_rate) over (order by question_year)
    ) as yoy_pct_change
from yearly
order by question_year
