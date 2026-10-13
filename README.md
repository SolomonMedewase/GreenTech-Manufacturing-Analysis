# GreenTech Manufacturing — Downtime & Operator Scheduling Analysis

## Project Overview

This project analyses manufacturing production data to identify the main causes of downtime, evaluate production efficiency and investigate potential operator scheduling conflicts.

Using **SQL Server and Power BI**, I performed data exploration, validation, transformation and analysis to generate insights that can support operational decision-making and manufacturing performance improvement.

## Business Problem

Manufacturing downtime can affect production efficiency, resource utilisation and operational performance. Understanding the factors contributing to downtime and identifying potential scheduling inefficiencies are important for improving manufacturing operations.

This project focuses on three key questions:

1. What are the main factors contributing to manufacturing downtime?
2. How does recorded downtime relate to additional production time?
3. Are overlapping operator assignments associated with increased downtime?

## Tools and Technologies

- **SQL Server / SSMS:** Data exploration, cleaning, validation, transformation and analysis.
- **Power BI:** Interactive dashboards and operational performance reporting.
- **SQL techniques:** JOINs, Common Table Expressions (CTEs), UNPIVOT, CASE statements, aggregate functions and SQL views.
## SQL Data Analysis Methodology

### 1. Data Exploration
- Explored four manufacturing datasets: production batches, line downtime, downtime factors and products.
- Examined table structures, record counts and relationships between datasets.
- Identified relevant fields for production efficiency and downtime analysis.

### 2. Data Quality Validation
- Checked production records for missing values and inconsistencies.
- Validated production start and end times.
- Compared recorded downtime against additional production time to assess data consistency.

### 3. Data Transformation
- Used SQL `UNPIVOT` to transform 13 downtime factor columns into rows for easier analysis.
- Created SQL views to structure production and downtime information.
- Calculated actual production duration and additional production time using `DATEDIFF`.

### 4. Manufacturing Downtime Analysis
- Analysed downtime frequency and duration across manufacturing processes.
- Investigated the contribution of different downtime factors.
- Compared recorded downtime with additional production time.

### 5. Operator Scheduling Analysis
- Used SQL self-joins to identify overlapping production batches assigned to the same operator.
- Applied Common Table Expressions (CTEs) and `UNION` to count distinct affected batches.
- Compared average downtime between overlapping and non-overlapping production batches.
- ## Key Findings and Business Insights

### 1. Downtime Data Validation

The analysis compared recorded manufacturing downtime against additional production time for 363 production batches with downtime records.

**Key results:**
- 363 production batches were evaluated.
- 323 batches (89.0%) had an exact match between recorded downtime and additional production time.
- 40 batches (11.0%) showed a discrepancy of just one minute.
- No batches had discrepancies exceeding one minute.

**Business Insight:**

Recorded downtime closely aligned with additional production time across the evaluated batches, indicating strong consistency between these measures. However, this relationship does not establish that recorded downtime caused all additional production time.

### 2. Operator Scheduling Overlaps

A SQL self-join was used to investigate overlapping production batches assigned to the same operator.

**Key results:**
- 27 overlapping production batch pairs were identified.
- 53 distinct production batches were involved in scheduling overlaps.

**Business Insight:**

Overlapping production assignments may indicate potential scheduling conflicts requiring operational review.

### 3. Downtime Comparison by Scheduling Status

The analysis compared average downtime between production batches with and without identified scheduling overlaps.

| Scheduling Status | Average Downtime |
|---|---:|
| Overlapping batches | 45.25 minutes |
| Non-overlapping batches | 48.84 minutes |

**Business Insight:**

Overlapping batches recorded approximately 3.59 fewer downtime minutes on average than non-overlapping batches.

This suggests that scheduling overlaps were not associated with increased average downtime in the analysed dataset. However, additional investigation would be necessary to assess their wider operational impact.
