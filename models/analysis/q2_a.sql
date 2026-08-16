{# For posts tagged with only 'python' or 'dbt', what is the year over year change
of question-to-answer ratio for the last 10 years? #}

with filtered_questions as (
    select 
        questions.question_id,
        questions.answer_count,
        extract(year from dim_questions.creation_date) as question_year
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
    where dim_questions.tag_count = 1
        and dim_questions.tags_group in ('python', 'dbt')
        and extract(year from dim_questions.creation_date) >= extract(year from current_date()) - 15
),

yearly as (
    select
        question_year,
        count(distinct question_id) as total_questions,
        sum(answer_count) as total_answers,
        safe_divide(sum(answer_count), count(distinct question_id)) as question_to_answer_ratio
    from filtered_questions
    group by question_year
)

select
    question_year,
    total_questions,
    total_answers,
    question_to_answer_ratio,
    lag(question_to_answer_ratio) over (order by question_year) as prev_year_ratio,
    question_to_answer_ratio - lag(question_to_answer_ratio) over (order by question_year) as yoy_change,
    safe_divide(
        question_to_answer_ratio - lag(question_to_answer_ratio) over (order by question_year),
        lag(question_to_answer_ratio) over (order by question_year)
    ) as yoy_pct_change
from yearly
order by question_year
