-- select * from  ref('dim_tags') }}
-- where tag_name = '2048'

select *  
from {{ ref('fact_questions') }} as questions
left join {{ ref('dim_group_tag') }} as group_tag
on questions.tags_group_id = group_tag.tags_group_id
where tag = 'accuracerdb'