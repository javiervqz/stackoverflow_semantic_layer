{# What tags on a Stack Overflow question lead to the most answers and the highest rate
of approved answers for the current year? What tags lead to the least? How about
combinations of tags? #}

with pre_select as (
select 
    questions.question_id,
    questions.answer_count,
    dim_questions.has_accepted_answer,
    question_tags.tag_name as tag
from {{ ref('fact_question') }} as questions
left join {{ ref('dim_question') }} as dim_questions
    on questions.question_id = dim_questions.question_id
left join {{ ref('fact_question_tag') }} as question_tags
    on dim_questions.question_id = question_tags.question_id
-- where extract(year from dim_questions.creation_date) = extract(year from current_date())
),

agg as (
select 
    tag, 
    count(distinct question_id) as count_questions,
    countif(has_accepted_answer) as questions_with_accepted,
    countif(not has_accepted_answer) as questions_without_accepted,
    safe_divide(countif(has_accepted_answer), count(distinct question_id)) as acceptance_rate
from pre_select
group by all
)

select * from agg
where count_questions > 10000
order by acceptance_rate desc