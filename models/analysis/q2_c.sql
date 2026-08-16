{# How do posts tagged with only 'python' compare to posts only tagged with 'dbt'?
Both question-to-answer ratio and acceptance rate, year over year for the last 10 years. #}

with filtered_questions as (
    select 
        questions.question_id,
        questions.answer_count,
        questions.has_accepted_answer,
        group_tag.tag,
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
        tag,
        question_year,
        count(distinct question_id) as total_questions,
        sum(answer_count) as total_answers,
        safe_divide(sum(answer_count), count(distinct question_id)) as question_to_answer_ratio,
        countif(has_accepted_answer) as questions_with_accepted,
        safe_divide(countif(has_accepted_answer), count(distinct question_id)) as acceptance_rate
    from filtered_questions
    group by tag, question_year
)

select
    tag,
    question_year,
    total_questions,
    total_answers,
    question_to_answer_ratio,
    lag(question_to_answer_ratio) over (partition by tag order by question_year) as prev_year_ratio,
    question_to_answer_ratio - lag(question_to_answer_ratio) over (partition by tag order by question_year) as ratio_yoy_change,
    questions_with_accepted,
    acceptance_rate,
    lag(acceptance_rate) over (partition by tag order by question_year) as prev_year_acceptance_rate,
    acceptance_rate - lag(acceptance_rate) over (partition by tag order by question_year) as acceptance_yoy_change
from yearly
order by tag, question_year
