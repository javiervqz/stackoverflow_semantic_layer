# MetricFlow Benchmarks vs. Models Analysis Queries

This document provides a 1-to-1 benchmark mapping comparing each manual SQL model in [`models/analysis/`](./models/analysis/) with its exact **MetricFlow (`mf`)** CLI query counterpart, verified with live execution against Google BigQuery.

---

## Benchmark Summary Index

| Analysis File | Business Question | MetricFlow Command Summary |
| :--- | :--- | :--- |
| [`q1.sql`](./models/analysis/q1.sql) | Individual Tag Acceptance Rates (`count_questions > 10000`) | `mf query --metrics tag_questions,tag_answers,tag_acceptance_rate --group-by question_tag__tag_name,question_tag__tag_lifetime_questions --where "question_tag__tag_lifetime_questions > 10000" --order -tag_acceptance_rate --limit 10` |
| [`q1_b.sql`](./models/analysis/q1_b.sql) | Tag Combinations / Group Tags Acceptance Rates (`count_questions > 1000`) | `mf query --metrics total_questions,total_answers,acceptance_rate --group-by question__tags_group,question__tag_count,question__tag_combination_volume --where "question__tag_combination_volume > 1000" --order -acceptance_rate --limit 10` |
| [`q2_a.sql`](./models/analysis/q2_a.sql) | YoY Question-to-Answer Ratio (`python` vs `dbt` single tag) | `mf query --metrics tag_questions,tag_answers,tag_question_to_answer_ratio --group-by question_tag__tag_name,metric_time__year,question_tag__tag_count --where "question_tag__tag_count = 1 and question_tag__tag_name in ('python', 'dbt')" --order metric_time__year` |
| [`q2_b.sql`](./models/analysis/q2_b.sql) | YoY Acceptance Rate (`python` vs `dbt` single tag) | `mf query --metrics tag_questions,tag_accepted_answers,tag_acceptance_rate --group-by question_tag__tag_name,metric_time__year,question_tag__tag_count --where "question_tag__tag_count = 1 and question_tag__tag_name in ('python', 'dbt')" --order metric_time__year` |
| [`q2_c.sql`](./models/analysis/q2_c.sql) | Comparative YoY `python` vs `dbt` (Both Metrics) | `mf query --metrics tag_questions,tag_answers,tag_question_to_answer_ratio,tag_acceptance_rate --group-by question_tag__tag_name,metric_time__year,question_tag__tag_count --where "question_tag__tag_count = 1 and question_tag__tag_name in ('python', 'dbt')" --order metric_time__year` |
| [`q3_a.sql`](./models/analysis/q3_a.sql) | Content Length Correlations (Deciles) | `mf query --metrics total_questions,avg_answers_per_question,answer_rate,acceptance_rate --group-by question__body_length --limit 10` |
| [`q3_b.sql`](./models/analysis/q3_b.sql) | Discrete Post Qualities (Tag Count & Edit Flag) | `mf query --metrics total_questions,avg_answers_per_question,answer_rate,acceptance_rate --group-by question__tag_count --order question__tag_count`<br>`mf query --metrics total_questions,avg_answers_per_question,answer_rate,acceptance_rate --group-by question__has_been_edited` |
| [`q3_c.sql`](./models/analysis/q3_c.sql) | Engagement Signals (Views, Comments, Scores) | `mf query --metrics total_questions,avg_answers_per_question,avg_views_per_question,avg_comments_per_question,avg_score_per_question,answer_rate,acceptance_rate --group-by question__has_been_edited` |

---

## 1. Individual Tag Performance (`q1.sql`)

### Analysis Query: [`models/analysis/q1.sql`](./models/analysis/q1.sql)
```sql
{# What tags on a Stack Overflow question lead to the most answers and the highest rate
of approved answers for the current year? What tags lead to the least? #}

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
```

### MetricFlow Counterpart:
```bash
.venv/bin/mf query --metrics tag_questions,tag_answers,tag_acceptance_rate \
                   --group-by question_tag__tag_name,question_tag__tag_lifetime_questions \
                   --where "question_tag__tag_lifetime_questions > 10000" \
                   --order -tag_acceptance_rate \
                   --limit 10
```

### Live Output from BigQuery:
```
question_tag__tag_name      question_tag__tag_lifetime_questions    tag_questions    tag_answers    tag_acceptance_rate
------------------------  --------------------------------------  ---------------  -------------  ---------------------
f#                                                         16546            16546          26809               0.734377
clojure                                                    17389            17389          30946               0.716487
awk                                                        31609            31607          74109               0.714430
dplyr                                                      32394            32390          51590               0.710806
functional-programming                                     18342            18339          37551               0.708163
data.table                                                 12822            12822          19781               0.706052
java-stream                                                10937            10936          21953               0.705651
regex                                                     252843           252839         494335               0.703040
haskell                                                    49561            49557          80666               0.702787
sed                                                        27622            27619          66021               0.696839
```

---

## 2. Tag Combinations / Group Tags Performance (`q1_b.sql`)

> **Note**: Both [`dim_question`](./models/marts/dim_question.sql) and [`fact_question_tag`](./models/marts/fact_question_tag.sql) canonicalize tag order alphabetically to eliminate fragmentation between permutations (e.g. `dbt|python` vs `python|dbt`).

### Analysis Query: [`models/analysis/q1_b.sql`](./models/analysis/q1_b.sql)
```sql
{# How about combinations of tags? Which tag combinations lead to the most answers
and the highest rate of accepted answers for the current year? #}

with agg as (
    select
        dim_questions.tags_group,
        dim_questions.tag_count as count_tags,
        count(distinct questions.question_id) as count_questions,
        sum(questions.answer_count) as count_answers,
        countif(dim_questions.has_accepted_answer) as questions_with_accepted,
        countif(not dim_questions.has_accepted_answer) as questions_without_accepted,
        safe_divide(countif(dim_questions.has_accepted_answer), count(distinct questions.question_id)) as acceptance_rate
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
    group by all
)

select * from agg
where count_questions > 1000
order by acceptance_rate desc
```

### MetricFlow Counterpart:
```bash
.venv/bin/mf query --metrics total_questions,total_answers,acceptance_rate \
                   --group-by question__tags_group,question__tag_count,question__tag_combination_volume \
                   --where "question__tag_combination_volume > 1000" \
                   --order -acceptance_rate \
                   --limit 10
```

### Live Output from BigQuery:
```
  question__tag_count  question__tags_group                  question__tag_combination_volume    total_questions    total_answers    acceptance_rate
---------------------  ----------------------------------  ----------------------------------  -----------------  ---------------  -----------------
                    2  jquery|jquery-selectors                                           2532               2532             6533           0.843997
                    3  javascript|jquery|jquery-selectors                                1115               1115             2888           0.815247
                    2  elisp|emacs                                                       1325               1325             2581           0.799245
                    3  .net|c#|regex                                                     1350               1350             3257           0.793333
                    2  regex|ruby                                                        2417               2417             5592           0.793132
                    1  f#                                                                3216               3216             5412           0.792289
                    1  clojure                                                           4155               4155             7949           0.790373
                    3  php|preg-replace|regex                                            1601               1601             3260           0.785134
                    3  php|preg-match|regex                                              1541               1541             3267           0.779364
                    3  .net|c#|linq                                                      1846               1846             4497           0.778982
```

---

## 3. Year-over-Year Tag Comparisons (`python` vs `dbt`)

### A. YoY Question-to-Answer Ratio: [`models/analysis/q2_a.sql`](./models/analysis/q2_a.sql)
```sql
with filtered_questions as (
    select 
        questions.question_id,
        questions.answer_count,
        extract(year from dim_questions.creation_date) as question_year
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
    inner join {{ ref('fact_question_tag') }} as question_tags
        on dim_questions.question_id = question_tags.question_id
    where dim_questions.tag_count = 1
        and question_tags.tag_name in ('python', 'dbt')
        and extract(year from dim_questions.creation_date) >= extract(year from current_date()) - 15
),

yearly as (
    select
        question_year,
        count(distinct question_id) as total_questions,
        sum(answer_count) as total_answers,
        safe_divide(sum(answer_count), count(distinct question_id)) as question_to_answer_ratio
    from filtered_questions
    group by question_year
)

select
    question_year,
    total_questions,
    total_answers,
    question_to_answer_ratio,
    lag(question_to_answer_ratio) over (order by question_year) as prev_year_ratio,
    question_to_answer_ratio - lag(question_to_answer_ratio) over (order by question_year) as yoy_change
from yearly
order by question_year
```

#### MetricFlow Counterpart:
```bash
.venv/bin/mf query --metrics tag_questions,tag_answers,tag_question_to_answer_ratio \
                   --group-by question_tag__tag_name,metric_time__year,question_tag__tag_count \
                   --where "question_tag__tag_count = 1 and question_tag__tag_name in ('python', 'dbt')" \
                   --order metric_time__year
```

---

### B. YoY Acceptance Rate: [`models/analysis/q2_b.sql`](./models/analysis/q2_b.sql)
```sql
with filtered_questions as (
    select 
        questions.question_id,
        dim_questions.has_accepted_answer,
        extract(year from dim_questions.creation_date) as question_year
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
    inner join {{ ref('fact_question_tag') }} as question_tags
        on dim_questions.question_id = question_tags.question_id
    where dim_questions.tag_count = 1
        and question_tags.tag_name in ('python', 'dbt')
        and extract(year from dim_questions.creation_date) >= extract(year from current_date()) - 15
),

yearly as (
    select
        question_year,
        count(distinct question_id) as total_questions,
        countif(has_accepted_answer) as questions_with_accepted,
        safe_divide(countif(has_accepted_answer), count(distinct question_id)) as acceptance_rate
    from filtered_questions
    group by question_year
)

select
    question_year,
    total_questions,
    questions_with_accepted,
    acceptance_rate,
    lag(acceptance_rate) over (order by question_year) as prev_year_rate,
    acceptance_rate - lag(acceptance_rate) over (order by question_year) as yoy_change
from yearly
order by question_year
```

#### MetricFlow Counterpart:
```bash
.venv/bin/mf query --metrics tag_questions,tag_accepted_answers,tag_acceptance_rate \
                   --group-by question_tag__tag_name,metric_time__year,question_tag__tag_count \
                   --where "question_tag__tag_count = 1 and question_tag__tag_name in ('python', 'dbt')" \
                   --order metric_time__year
```

---

### C. Full Comparative Analysis: [`models/analysis/q2_c.sql`](./models/analysis/q2_c.sql)
```sql
with filtered_questions as (
    select 
        questions.question_id,
        questions.answer_count,
        dim_questions.has_accepted_answer,
        question_tags.tag_name as tag,
        extract(year from dim_questions.creation_date) as question_year
    from {{ ref('fact_question') }} as questions
    inner join {{ ref('dim_question') }} as dim_questions
        on questions.question_id = dim_questions.question_id
    inner join {{ ref('fact_question_tag') }} as question_tags
        on dim_questions.question_id = question_tags.question_id
    where dim_questions.tag_count = 1
        and question_tags.tag_name in ('python', 'dbt')
        and extract(year from dim_questions.creation_date) >= extract(year from current_date()) - 15
),

yearly as (
    select
        tag,
        question_year,
        count(distinct question_id) as total_questions,
        sum(answer_count) as total_answers,
        safe_divide(sum(answer_count), count(distinct question_id)) as question_to_answer_ratio,
        countif(has_accepted_answer) as questions_with_accepted,
        safe_divide(countif(has_accepted_answer), count(distinct question_id)) as acceptance_rate
    from filtered_questions
    group by tag, question_year
)

select
    tag,
    question_year,
    total_questions,
    total_answers,
    question_to_answer_ratio,
    questions_with_accepted,
    acceptance_rate
from yearly
order by tag, question_year
```

#### MetricFlow Counterpart:
```bash
.venv/bin/mf query --metrics tag_questions,tag_answers,tag_question_to_answer_ratio,tag_acceptance_rate \
                   --group-by question_tag__tag_name,metric_time__year,question_tag__tag_count \
                   --where "question_tag__tag_count = 1 and question_tag__tag_name in ('python', 'dbt')" \
                   --order metric_time__year
```

#### Live Output from BigQuery:
```
metric_time__year    question_tag__tag_name    question_tag__tag_count    tag_questions    tag_answers    tag_question_to_answer_ratio    tag_acceptance_rate
-------------------  ------------------------  -------------------------  ---------------  -------------  ------------------------------  ---------------------
2008-01-01T00:00:00  python                                            1              107            647                         6.04673               0.859813
2009-01-01T00:00:00  python                                            1             1025           4567                         4.45561               0.785366
2010-01-01T00:00:00  python                                            1             2270           7933                         3.49471               0.746256
2011-01-01T00:00:00  python                                            1             3818          11251                         2.94683               0.722630
2012-01-01T00:00:00  python                                            1             5749          15118                         2.62967               0.720821
2013-01-01T00:00:00  python                                            1             7819          18068                         2.31078               0.651746
2014-01-01T00:00:00  python                                            1             8537          16792                         1.96697               0.614619
2015-01-01T00:00:00  python                                            1             9781          18582                         1.89981               0.568960
2016-01-01T00:00:00  python                                            1            10344          18970                         1.83391               0.525232
2017-01-01T00:00:00  python                                            1            11683          19851                         1.69914               0.491312
2018-01-01T00:00:00  python                                            1            11614          19653                         1.69218               0.491992
2019-01-01T00:00:00  python                                            1            14503          24706                         1.70351               0.488106
2020-01-01T00:00:00  dbt                                               1               31             43                         1.38710               0.419355
2020-01-01T00:00:00  python                                            1            16256          26816                         1.64961               0.454970
2021-01-01T00:00:00  dbt                                               1               58             66                         1.13793               0.258621
2021-01-01T00:00:00  python                                            1            15811          24057                         1.52154               0.430144
2022-01-01T00:00:00  dbt                                               1               79             84                         1.06329               0.278481
2022-01-01T00:00:00  python                                            1            12809          16116                         1.25818               0.354048
```

---

## 4. Post Qualities & Engagement Correlations

### A. Slicing by Tag Count: [`models/analysis/q3_b.sql`](./models/analysis/q3_b.sql)
```sql
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
```

#### MetricFlow Counterpart:
```bash
.venv/bin/mf query --metrics total_questions,avg_answers_per_question,answer_rate,acceptance_rate \
                   --group-by question__tag_count \
                   --order question__tag_count
```

#### Live Output from BigQuery:
```
  question__tag_count    total_questions    avg_answers_per_question    answer_rate    acceptance_rate
---------------------  -----------------  --------------------------  -------------  -----------------
                    1            2730236                     1.52037       0.871343           0.498895
                    2            6011683                     1.51914       0.866323           0.519997
                    3            6618852                     1.48183       0.856229           0.515829
                    4            4568721                     1.45422       0.848428           0.509751
                    5            3090516                     1.38760       0.832449           0.493110
                    6                119                     1.42017       0.857143           0.428571
```

---

### B. Slicing by Edit Flag & Engagement Signals: [`models/analysis/q3_b.sql`](./models/analysis/q3_b.sql) & [`models/analysis/q3_c.sql`](./models/analysis/q3_c.sql)
```sql
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
```

#### MetricFlow Counterpart:
```bash
.venv/bin/mf query --metrics total_questions,avg_answers_per_question,avg_views_per_question,avg_comments_per_question,avg_score_per_question,answer_rate,acceptance_rate \
                   --group-by question__has_been_edited
```

#### Live Output from BigQuery:
```
question__has_been_edited      total_questions    avg_answers_per_question    avg_views_per_question    avg_comments_per_question    avg_score_per_question    answer_rate    acceptance_rate
---------------------------  -----------------  --------------------------  ------------------------  ---------------------------  ------------------------  -------------  -----------------
False                                 10460205                     1.33829                   1722.93                      1.47473                   1.35114       0.840411           0.497932
True                                  12559922                     1.59438                   3747.76                      2.41036                   2.93414       0.868831           0.521246
```
