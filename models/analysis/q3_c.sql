{# What engagement signals correlate with answer rate and acceptance rate?
Analyzes comment_count, score, and view_count using decile bucketing.
Note: these metrics are partially endogenous — posts with more visibility
naturally attract more answers — so interpret as co-occurring signals
rather than causal drivers. #}

with bucketed as (
    select
        question_id,
        answer_count,
        has_accepted_answer,
        comment_count,
        score,
        view_count,
        ntile(10) over (order by comment_count) as comment_decile,
        ntile(4) over (order by score) as score_decile,
        ntile(10) over (order by view_count) as view_decile
    from {{ ref('fact_questions') }}
)

select
    'comment_count' as quality,
    comment_decile as decile,
    min(comment_count) as min_value,
    max(comment_count) as max_value,
    count(*) as total_questions,
    round(safe_divide(sum(answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(has_accepted_answer), count(*)) as acceptance_rate
from bucketed
group by comment_decile

union all

select
    'score' as quality,
    score_decile as decile,
    min(score) as min_value,
    max(score) as max_value,
    count(*) as total_questions,
    round(safe_divide(sum(answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(has_accepted_answer), count(*)) as acceptance_rate
from bucketed
group by score_decile

union all

select
    'view_count' as quality,
    view_decile as decile,
    min(view_count) as min_value,
    max(view_count) as max_value,
    count(*) as total_questions,
    round(safe_divide(sum(answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(has_accepted_answer), count(*)) as acceptance_rate
from bucketed
group by view_decile

order by quality, decile
