{# What tags on a Stack Overflow question lead to the most answers and the highest rate
of approved answers for the current year? What tags lead to the least? How about
combinations of tags? #}

with pre_select as (
select 
    questions.question_id,
    questions.answer_count,
    questions.has_accepted_answer,
    group_tag.tag
from {{ ref('fact_questions') }} as questions
left join {{ ref('dim_group_tag') }} as group_tag
    on questions.tags_group_id = group_tag.tags_group_id
-- where extract(year from questions.creation_date) = extract(year from current_date())
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