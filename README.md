# Stack Overflow dbt Analytics: Canonical Tags Impact Analysis

This repository contains the dbt transformation pipeline and semantic layer for Stack Overflow public data, modeling over 23 million questions, answers, tags, and user interactions.


---

## X. Why creating a canonical intermedite: Impact Metrics

When Stack Overflow users submit question posts, tags are stored as pipe-delimited strings (e.g., `javascript|html|css|jquery` vs `html|css|javascript|jquery`). Because tag insertion order is non-deterministic, identical combinations of tags produce different string permutations. 

By extracting distinct tag combinations into an intermediate layer ([`int_canonical_tags`](./models/intermediate/int_canonical_tags.sql)), sorting the constituent tags alphabetically, and joining the results back into [`dim_question`](./models/marts/dim_question.sql), we achieved significant analytical accuracy improvements and computational savings:

| Metric | Value | Impact / Interpretation |
| :--- | :--- | :--- |
| **Total Questions Evaluated** | **23,020,127** | Total question posts in the warehouse |
| **Multi-Tag Questions** | **20,289,891** (88.13%) | Questions with 2 or more tags vulnerable to permutation fragmentation |
| **Distinct Raw Tag Combinations** | **8,448,317** | Raw unique tag string permutations in staging |
| **Distinct Canonical Tag Groups** | **8,205,709** | True unique tag combinations after alphabetical normalization |
| **Redundant Permutations Collapsed** | **242,608** | **242,608 unique fragmented strings eliminated** (-2.87%) |
| **Questions Affected by Permutation Fragmentation** | **5,333,956** (**23.17%**) | **~5.33M questions** rescued from fragmented reporting buckets |
| **Compute / String Transformation Savings** | **63.30%** | String split/sort executed on **8.45M distinct strings** instead of **23.02M question rows** |

