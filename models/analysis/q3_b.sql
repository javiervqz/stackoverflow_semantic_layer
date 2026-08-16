{# What discrete post qualities correlate with answer rate and acceptance rate?
Analyzes tag count (natural small values) and whether the post was edited. #}

select
    'tag_count' as quality,
    cast(dim_questions.tag_count as string) as bucket,
    count(*) as total_questions,
    round(safe_divide(sum(questions.answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(questions.answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(dim_questions.has_accepted_answer), count(*)) as acceptance_rate
from {{ ref('fact_question') }} as questions
inner join {{ ref('dim_question') }} as dim_questions
    on questions.question_id = dim_questions.question_id
group by dim_questions.tag_count

union all

select
    'has_been_edited' as quality,
    cast(dim_questions.has_been_edited as string) as bucket,
    count(*) as total_questions,
    round(safe_divide(sum(questions.answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(questions.answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(dim_questions.has_accepted_answer), count(*)) as acceptance_rate
from {{ ref('fact_question') }} as questions
inner join {{ ref('dim_question') }} as dim_questions
    on questions.question_id = dim_questions.question_id
group by dim_questions.has_been_edited

order by quality, bucket
