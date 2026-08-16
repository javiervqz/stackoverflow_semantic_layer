-- select * from  ref('dim_tags') }}
-- where tag_name = '2048'

select *  
from {{ ref('fact_question') }} as questions
left join {{ ref('dim_question') }} as dim_questions
    on questions.question_id = dim_questions.question_id
left join {{ ref('fact_question_tag') }} as question_tags
    on dim_questions.question_id = question_tags.question_id
where question_tags.tag_name = 'accuracerdb'