{# What tags on a Stack Overflow question lead to the most answers and the highest rate
of approved answers for the current year? What tags lead to the least? #}

with agg as (
    select
        tag_name as tag,
        sum(total_questions) as count_questions,
        sum(questions_with_accepted_answer) as questions_with_accepted,
        sum(total_questions) - sum(questions_with_accepted_answer) as questions_without_accepted,
        safe_divide(sum(questions_with_accepted_answer), sum(total_questions)) as acceptance_rate
    from {{ ref('fact_tag_daily') }}
    group by tag_name
)

select * from agg
where count_questions > 10000
order by acceptance_rate desc