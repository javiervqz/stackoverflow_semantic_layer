# MetricFlow Benchmarks vs. Models Analysis Queries

This document provides a benchmark mapping comparing each analysis model in [`models/analysis/`](./models/analysis/) with its verified results and MetricFlow query representation.

---

## Benchmark Summary Index

| Analysis File | Business Question | MetricFlow Command Summary |
| :--- | :--- | :--- |
| [`q1_a.sql`](./models/analysis/q1_a.sql) | Individual Tag Acceptance Rates (`count_questions > 10000`) | `mf query --metrics tag_total_questions,tag_total_answers,tag_questions_with_accepted_answer,tag_acceptance_rate --group-by tag_daily__tag_name,tag__tag_volume --where "tag__tag_volume > 10000" --order -tag_acceptance_rate --limit 10` |
| [`q1_b.sql`](./models/analysis/q1_b.sql) | Tag Combinations / Group Tags Acceptance Rates (`count_questions > 1000`) | `mf query --metrics total_questions,total_answers,acceptance_rate --group-by question__tags_group,question__tag_count,question__tag_combination_volume --where "question__tag_combination_volume > 1000" --order -acceptance_rate --limit 10` |
| [`q2_a.sql`](./models/analysis/q2_a.sql) | YoY Question-to-Answer Ratio (`python` vs `dbt` single tag) | `mf query --metrics total_questions,total_answers,question_to_answer_ratio --group-by question__tags_group,metric_time__year,question__tag_count --where "question__tag_count = 1 and question__tags_group in ('python', 'dbt')" --order metric_time__year` |
| [`q2_b.sql`](./models/analysis/q2_b.sql) | YoY Acceptance Rate (`python` vs `dbt` single tag) | `mf query --metrics total_questions,acceptance_rate --group-by question__tags_group,metric_time__year,question__tag_count --where "question__tag_count = 1 and question__tags_group in ('python', 'dbt')" --order metric_time__year` |
| [`q2_c.sql`](./models/analysis/q2_c.sql) | Comparative YoY `python` vs `dbt` (Both Metrics) | `mf query --metrics total_questions,total_answers,question_to_answer_ratio,acceptance_rate --group-by question__tags_group,metric_time__year,question__tag_count --where "question__tag_count = 1 and question__tags_group in ('python', 'dbt')" --order metric_time__year` |
| [`q3_a.sql`](./models/analysis/q3_a.sql) | Content Length Correlations (Deciles) | Decile bucketing on `body_length` and `title_length` (SQL analysis model) |
| [`q3_b.sql`](./models/analysis/q3_b.sql) | Discrete Post Qualities (Tag Count & Edit Flag) | `mf query --metrics total_questions,avg_answers_per_question,answer_rate,acceptance_rate --group-by question__tag_count --order question__tag_count`<br>`mf query --metrics total_questions,avg_answers_per_question,answer_rate,acceptance_rate --group-by question__has_been_edited` |
| [`q3_c.sql`](./models/analysis/q3_c.sql) | Engagement Signals (Views, Comments, Scores) | `mf query --metrics total_questions,avg_answers_per_question,avg_views_per_question,avg_comments_per_question,avg_score_per_question,answer_rate,acceptance_rate --group-by question__has_been_edited` |

---

## 1. Individual Tag Performance ([`q1_a.sql`](./models/analysis/q1_a.sql))

### MetricFlow Command:
```bash
.venv/bin/mf query --metrics tag_total_questions,tag_total_answers,tag_questions_with_accepted_answer,tag_acceptance_rate \
                   --group-by tag_daily__tag_name,tag__tag_volume \
                   --where "tag__tag_volume > 10000" \
                   --order -tag_acceptance_rate \
                   --limit 10
```

### Results:

| Tag | Tag Lifetime Volume | Total Questions | Total Answers | Accepted Answers | Acceptance Rate |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `f#` | 16,546 | 16,546 | 26,809 | 12,151 | 0.734377 |
| `clojure` | 17,389 | 17,389 | 30,946 | 12,459 | 0.716487 |
| `awk` | 31,609 | 31,607 | 74,109 | 22,581 | 0.714430 |
| `dplyr` | 32,394 | 32,390 | 51,590 | 23,023 | 0.710806 |
| `functional-programming` | 18,342 | 18,339 | 37,551 | 12,987 | 0.708163 |
| `data.table` | 12,822 | 12,822 | 19,781 | 9,053 | 0.706052 |
| `java-stream` | 10,937 | 10,936 | 21,953 | 7,717 | 0.705651 |
| `regex` | 252,843 | 252,839 | 494,335 | 177,756 | 0.703040 |
| `haskell` | 49,561 | 49,557 | 80,666 | 34,828 | 0.702787 |
| `sed` | 27,622 | 27,619 | 66,021 | 19,246 | 0.696839 |

---

## 2. Tag Combinations Performance ([`q1_b.sql`](./models/analysis/q1_b.sql))

### MetricFlow Command:
```bash
.venv/bin/mf query --metrics total_questions,total_answers,acceptance_rate \
                   --group-by question__tags_group,question__tag_count,question__tag_combination_volume \
                   --where "question__tag_combination_volume > 1000" \
                   --order -acceptance_rate \
                   --limit 10
```

### Results:

| Tag Count | Tag Combination (`tags_group`) | Combination Volume | Total Questions | Total Answers | Acceptance Rate |
| :---: | :--- | :---: | :---: | :---: | :---: |
| 2 | `jquery\|jquery-selectors` | 2,532 | 2,532 | 6,533 | 0.843997 |
| 3 | `javascript\|jquery\|jquery-selectors` | 1,115 | 1,115 | 2,888 | 0.815247 |
| 2 | `elisp\|emacs` | 1,325 | 1,325 | 2,581 | 0.799245 |
| 3 | `.net\|c#\|regex` | 1,350 | 1,350 | 3,257 | 0.793333 |
| 2 | `regex\|ruby` | 2,417 | 2,417 | 5,592 | 0.793132 |
| 1 | `f#` | 3,216 | 3,216 | 5,412 | 0.792289 |
| 1 | `clojure` | 4,155 | 4,155 | 7,949 | 0.790373 |
| 3 | `php\|preg-replace\|regex` | 1,601 | 1,601 | 3,260 | 0.785134 |
| 3 | `php\|preg-match\|regex` | 1,541 | 1,541 | 3,267 | 0.779364 |
| 3 | `.net\|c#\|linq` | 1,846 | 1,846 | 4,497 | 0.778982 |

---

## 3. Year-over-Year Comparative Analysis: `python` vs `dbt` ([`q2_a.sql`](./models/analysis/q2_a.sql), [`q2_b.sql`](./models/analysis/q2_b.sql), [`q2_c.sql`](./models/analysis/q2_c.sql))

### MetricFlow Command:
```bash
.venv/bin/mf query --metrics total_questions,total_answers,question_to_answer_ratio,acceptance_rate \
                   --group-by question__tags_group,metric_time__year,question__tag_count \
                   --where "question__tag_count = 1 and question__tags_group in ('python', 'dbt')" \
                   --order metric_time__year
```

### Results:

| Year | Tag Count | Tag | Total Questions | Total Answers | Question-to-Answer Ratio | Acceptance Rate |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: |
| 2008 | 1 | `python` | 107 | 647 | 6.04673 | 0.859813 |
| 2009 | 1 | `python` | 1,025 | 4,567 | 4.45561 | 0.785366 |
| 2010 | 1 | `python` | 2,270 | 7,933 | 3.49471 | 0.746256 |
| 2011 | 1 | `python` | 3,818 | 11,251 | 2.94683 | 0.722630 |
| 2012 | 1 | `python` | 5,749 | 15,118 | 2.62967 | 0.720821 |
| 2013 | 1 | `python` | 7,819 | 18,068 | 2.31078 | 0.651746 |
| 2014 | 1 | `python` | 8,537 | 16,792 | 1.96697 | 0.614619 |
| 2015 | 1 | `python` | 9,781 | 18,582 | 1.89981 | 0.568960 |
| 2016 | 1 | `python` | 10,344 | 18,970 | 1.83391 | 0.525232 |
| 2017 | 1 | `python` | 11,683 | 19,851 | 1.69914 | 0.491312 |
| 2018 | 1 | `python` | 11,614 | 19,653 | 1.69218 | 0.491992 |
| 2019 | 1 | `python` | 14,503 | 24,706 | 1.70351 | 0.488106 |
| 2020 | 1 | `dbt` | 31 | 43 | 1.38710 | 0.419355 |
| 2020 | 1 | `python` | 16,256 | 26,816 | 1.64961 | 0.454970 |
| 2021 | 1 | `dbt` | 58 | 66 | 1.13793 | 0.258621 |
| 2021 | 1 | `python` | 15,811 | 24,057 | 1.52154 | 0.430144 |
| 2022 | 1 | `dbt` | 79 | 84 | 1.06329 | 0.278481 |
| 2022 | 1 | `python` | 12,809 | 16,116 | 1.25818 | 0.354048 |

---

## 4. Content Length Deciles ([`q3_a.sql`](./models/analysis/q3_a.sql))

### Results:

| Quality | Decile | Min Value | Max Value | Total Questions | Avg Answers per Question |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `body_length` | 1 | 17 | 340 | 2,302,013 | 1.72 |
| `body_length` | 2 | 340 | 495 | 2,302,013 | 1.63 |
| `body_length` | 3 | 495 | 642 | 2,302,013 | 1.59 |
| `body_length` | 4 | 642 | 804 | 2,302,013 | 1.55 |
| `body_length` | 5 | 804 | 995 | 2,302,013 | 1.51 |
| `body_length` | 6 | 995 | 1,234 | 2,302,013 | 1.47 |
| `body_length` | 7 | 1,234 | 1,558 | 2,302,013 | 1.42 |
| `body_length` | 8 | 1,558 | 2,066 | 2,302,012 | 1.37 |
| `body_length` | 9 | 2,066 | 3,132 | 2,302,012 | 1.30 |
| `body_length` | 10 | 3,132 | 115,918 | 2,302,012 | 1.22 |
| `title_length` | 1 | 9 | 31 | 2,302,013 | 1.66 |
| `title_length` | 2 | 31 | 37 | 2,302,013 | 1.58 |
| `title_length` | 3 | 37 | 42 | 2,302,013 | 1.55 |
| `title_length` | 4 | 42 | 47 | 2,302,013 | 1.51 |
| `title_length` | 5 | 47 | 51 | 2,302,013 | 1.49 |
| `title_length` | 6 | 51 | 56 | 2,302,013 | 1.47 |
| `title_length` | 7 | 56 | 62 | 2,302,013 | 1.44 |
| `title_length` | 8 | 62 | 70 | 2,302,012 | 1.42 |
| `title_length` | 9 | 70 | 82 | 2,302,012 | 1.38 |
| `title_length` | 10 | 82 | 150 | 2,302,012 | 1.30 |

---

## 5. Post Qualities: Tag Count Breakdown ([`q3_b.sql`](./models/analysis/q3_b.sql))

### MetricFlow Command:
```bash
.venv/bin/mf query --metrics total_questions,avg_answers_per_question,answer_rate,acceptance_rate \
                   --group-by question__tag_count \
                   --order question__tag_count
```

### Results:

| Tag Count | Total Questions | Avg Answers per Question | Answer Rate | Acceptance Rate |
| :---: | :---: | :---: | :---: | :---: |
| 1 | 2,730,236 | 1.52037 | 0.871343 | 0.498895 |
| 2 | 6,011,683 | 1.51914 | 0.866323 | 0.519997 |
| 3 | 6,618,852 | 1.48183 | 0.856229 | 0.515829 |
| 4 | 4,568,721 | 1.45422 | 0.848428 | 0.509751 |
| 5 | 3,090,516 | 1.38760 | 0.832449 | 0.493110 |
| 6 | 119 | 1.42017 | 0.857143 | 0.428571 |

---

## 6. Post Qualities & Engagement Signals ([`q3_b.sql`](./models/analysis/q3_b.sql), [`q3_c.sql`](./models/analysis/q3_c.sql))

### MetricFlow Command:
```bash
.venv/bin/mf query --metrics total_questions,avg_answers_per_question,avg_views_per_question,avg_comments_per_question,avg_score_per_question,answer_rate,acceptance_rate \
                   --group-by question__has_been_edited
```

### Results:

| Has Been Edited | Total Questions | Avg Answers / Question | Avg Views / Question | Avg Comments / Question | Avg Score / Question | Answer Rate | Acceptance Rate |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `False` | 10,460,205 | 1.33829 | 1,722.93 | 1.47473 | 1.35114 | 0.840411 | 0.497932 |
| `True` | 12,559,922 | 1.59438 | 3,747.76 | 2.41036 | 2.93414 | 0.868831 | 0.521246 |


