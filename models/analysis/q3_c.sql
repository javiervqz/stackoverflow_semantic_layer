{# What engagement signals correlate with answer rate and acceptance rate?
Analyzes comment_count, score, and view_count using decile bucketing.
Note: these metrics are non conclusive because naturally, posts with more visibility attract more answers, so interpret as co-occurring signals
rather than causal drivers. #}

with bucketed as (
    select
        questions.question_id,
        questions.answer_count,
        dim_questions.has_accepted_answer,
        questions.comment_count,
        questions.score,
        questions.view_count,
        ntile(10) over (order by questions.comment_count) as comment_decile,
        ntile(4) over (order by questions.score) as score_decile,
        ntile(10) over (order by questions.view_count) as view_decile
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
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
