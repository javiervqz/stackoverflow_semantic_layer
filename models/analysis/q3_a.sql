{# What content qualities correlate with answer rate and acceptance rate?
Analyzes body length and title length using decile bucketing. #}

with bucketed as (
    select
        question_id,
        answer_count,
        has_accepted_answer,
        body_length,
        title_length,
        ntile(10) over (order by body_length) as body_length_decile,
        ntile(10) over (order by title_length) as title_length_decile
    from {{ ref('fact_questions') }}
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
