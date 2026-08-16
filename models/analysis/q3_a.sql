{# What content qualities correlate with answer rate and acceptance rate?
Analyzes body length and title length using decile bucketing. #}

with bucketed as (
    select
        questions.question_id,
        questions.answer_count,
        dim_questions.has_accepted_answer,
        dim_questions.body_length,
        dim_questions.title_length,
        ntile(10) over (order by dim_questions.body_length) as body_length_decile,
        ntile(10) over (order by dim_questions.title_length) as title_length_decile
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
)

select
    'body_length' as quality,
    body_length_decile as decile,
    min(body_length) as min_value,
    max(body_length) as max_value,
    count(*) as total_questions,
    round(safe_divide(sum(answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(has_accepted_answer), count(*)) as acceptance_rate
from bucketed
group by body_length_decile

union all

select
    'title_length' as quality,
    title_length_decile as decile,
    min(title_length) as min_value,
    max(title_length) as max_value,
    count(*) as total_questions,
    round(safe_divide(sum(answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(has_accepted_answer), count(*)) as acceptance_rate
from bucketed
group by title_length_decile

order by quality, decile
