{# What discrete post qualities correlate with answer rate and acceptance rate?
Analyzes tag count (natural small values) and whether the post was edited. #}

select
    'tag_count' as quality,
    cast(tag_count as string) as bucket,
    count(*) as total_questions,
    round(safe_divide(sum(answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(has_accepted_answer), count(*)) as acceptance_rate
from {{ ref('fact_questions') }}
group by tag_count

union all

select
    'has_been_edited' as quality,
    cast(has_been_edited as string) as bucket,
    count(*) as total_questions,
    round(safe_divide(sum(answer_count), count(*)), 2) as avg_answers_per_question,
    safe_divide(countif(answer_count > 0), count(*)) as answer_rate,
    safe_divide(countif(has_accepted_answer), count(*)) as acceptance_rate
from {{ ref('fact_questions') }}
group by has_been_edited

order by quality, bucket
