USE greentech;
GO



/*
PROJECT: GREENTECH MANUFACTURING
PRODUCTION DOWNTIME & OPERATOR SCHEDULING ANALYSIS

TOOLS: SQL Server, SSMS, Power BI

PROJECT OBJECTIVE:
Analyse manufacturing production data to identify
downtime patterns, production delays, and
operator scheduling inefficiencies.

KEY ANALYSIS AREAS:
1. Data Exploration and Validation
2. Data Cleaning and Transformation
3. Production Downtime Analysis
4. Downtime Factors and Operator Performance
5. Overlapping Batch and Scheduling Analysis

DATASETS:
- line_productivity_batches
- line_downtime
- downtime_factors
- products
*/


-- =====================================================
-- SECTION 1: DATA EXPLORATION
-- =====================================================
-- Objective:
-- Examine the structure and contents of the four
-- datasets used in the GreenTech manufacturing analysis.
-- =====================================================

SELECT * FROM downtime_factors;
SELECT * FROM line_downtime;
SELECT * FROM line_productivity_batches;
SELECT * FROM products;

-- 1.1 Validate record counts across source tables

SELECT COUNT (*) AS rows_downtime_Factors FROM downtime_factors;
SELECT COUNT (*) AS rows_line_downtime_Factors FROM line_downtime;
SELECT COUNT (*) AS rows_product_batches FROM line_productivity_batches;
SELECT COUNT (*) AS rows_product FROM products;

--Factor 1 null count
SELECT COUNT (*) AS factor1_null_count FROM line_downtime
WHERE Factor_1 is NULL;

--Factor 2 null count
SELECT COUNT (*) AS factor2_null_count FROM line_downtime
WHERE Factor_2 is NULL;

-- All null count 
SELECT COUNT (*) AS all_factors_null_count FROM line_downtime
WHERE COALESCE(Factor_1, Factor_2, Factor_3,Factor_4, Factor_5, Factor_6, Factor_7, 
Factor_8, Factor_9, Factor_10, Factor_11, Factor_12, Factor_13 ) IS NULL;


-- =====================================================
-- SECTION 2: DATA QUALITY VALIDATION
-- =====================================================
-- Objective:
-- Validate production dates and identify potential
-- inconsistencies in manufacturing records.
-- =====================================================

-- 2.1 Check production dates against batch records

WITH start_dates AS (
SELECT Date, CAST(Start_TIME as Date) AS Start_date 
FROM line_productivity_batches)
SELECT * FROM start_dates
WHERE Date != Start_Date;


-- =====================================================
-- SECTION 3: DATA CLEANING AND TRANSFORMATION
-- =====================================================
-- Objective:
-- Transform raw manufacturing downtime records
-- into a structured format suitable for analysis.
--
-- 3.1 Transform downtime factors using UNPIVOT
--
-- The original dataset contains 13 downtime factor
-- columns (Factor_1 through Factor_13).
--
-- UNPIVOT converts these columns into rows,
-- allowing downtime factors to be analysed
-- individually and linked to their descriptions.
-- =====================================================
GO  
CREATE OR ALTER VIEW downtimeS AS
SELECT Batch_ID, REPLACE(Factor, 'Factor_', '') AS Factor_ID, Minutes FROM line_downtime
UNPIVOT(Minutes FOR Factor IN (Factor_1, Factor_2, Factor_3, Factor_4, Factor_5, Factor_6,
Factor_7, Factor_8, Factor_9, Factor_10, Factor_11, Factor_12, Factor_13)) AS UnpivotDowntimes
GO

SELECT * FROM downtimeS
ORDER BY Batch_ID;

-- New batch production table (sdate as start date, extract date from start and end time)
GO
CREATE OR ALTER VIEW batch_pd AS
SELECT Date as Start_Date, Product_ID, Batch_ID,Operator, CAST(End_Time AS Date) AS End_Date,
CAST(Start_Time AS Time) AS Start_Time, CAST(End_Time AS Time) AS End_time, planned_Min_Batch_Hours,
 DATEDIFF(MINUTE, Start_Time, End_Time) / 60.0
    AS Actual_Duration,

DATEDIFF(MINUTE, Start_Time, End_Time) / 60.0
    - Planned_Min_Batch_Hours AS Extra_Time_Hr
FROM line_productivity_batches
GO

SELECT * FROM batch_pd


--Validating Downtime minutes against planned production time and reported start/end time
SELECT batch_pd.Batch_ID, SUM(Minutes) AS accounted_delay_minutes, Extra_Time_Hr * 60 AS Extra_Time_Minutes FROM batch_pd
JOIN downtimeS ON batch_pd.Batch_ID =downtimeS.Batch_ID
GROUP BY batch_pd.Batch_ID,Extra_Time_Hr;
    


SELECT
    b.Batch_ID,
    SUM(d.Minutes) AS Accounted_Delay_Minutes,
    b.Extra_Time_Hr * 60 AS Extra_Time_Minutes,

    SUM(d.Minutes) - (b.Extra_Time_Hr * 60)
        AS Difference_Minutes

FROM dbo.batch_pd AS b

INNER JOIN dbo.downtimeS AS d
    ON b.Batch_ID = d.Batch_ID

GROUP BY
    b.Batch_ID,
    b.Extra_Time_Hr

ORDER BY
    ABS(SUM(d.Minutes) - (b.Extra_Time_Hr * 60)) DESC;


WITH DowntimeComparison AS (
    SELECT
        b.Batch_ID,
        SUM(d.Minutes) AS Accounted_Delay_Minutes,
        b.Extra_Time_Hr * 60 AS Extra_Time_Minutes,
        SUM(d.Minutes) - (b.Extra_Time_Hr * 60)
            AS Difference_Minutes
    FROM dbo.batch_pd AS b
    INNER JOIN dbo.downtimeS AS d
        ON b.Batch_ID = d.Batch_ID
    GROUP BY
        b.Batch_ID,
        b.Extra_Time_Hr
)
SELECT
    COUNT(*) AS Total_Batches,
    SUM(CASE WHEN Difference_Minutes = 0
        THEN 1 ELSE 0 END) AS Exact_Matches,
    SUM(CASE WHEN ABS(Difference_Minutes) = 1
        THEN 1 ELSE 0 END) AS One_Minute_Difference,
    SUM(CASE WHEN ABS(Difference_Minutes) > 1
        THEN 1 ELSE 0 END) AS Larger_Differences,
    MAX(ABS(Difference_Minutes)) AS Maximum_Difference_Minutes
FROM DowntimeComparison;


-- =====================================================
-- DATA VALIDATION FINDINGS
-- =====================================================
-- Total batches with recorded downtime: 363
-- Exact downtime-to-extra-time matches: 323 (89.0%)
-- Batches with a 1-minute difference: 40 (11.0%)
-- Batches with differences above 1 minute: 0
-- Maximum absolute discrepancy: 1 minute
--
-- Conclusion:
-- Recorded downtime closely aligns with additional
-- production time for batches with downtime records.
-- All 363 batches have discrepancies within 1 minute.
-- =====================================================




-- =====================================================
-- SECTION 4: MANUFACTURING DOWNTIME ANALYSIS
-- =====================================================
-- Objective:
-- Analyse production downtime to identify the
-- major causes of operational interruptions.
--
-- Key areas:
-- 1. Total downtime duration
-- 2. Downtime frequency by factor
-- 3. Downtime duration by factor
-- 4. Downtime patterns across production batches
-- =====================================================

--Downtime key factors 
SELECT Factor_Name, COUNT(Batch_ID) AS FREQUENCY, SUM(Minutes) AS Delay_Mins FROM downtimeS
JOIN downtime_factors ON downtimeS.Factor_ID = downtime_factors.Factor_ID
GROUP BY Factor_Name
ORDER BY Frequency DESC;

--Operator vs Non operator Error
SELECT 
CASE Operator_error
WHEN 1 THEN 'Yes'
WHEN 0 THEN 'No'
END AS Operator_Error,
 COUNT(Batch_ID) AS FREQUENCY, SUM(Minutes) AS Delay_Mins FROM downtimeS
 JOIN downtime_factors ON downtimeS.Factor_ID= downtime_factors.Factor_ID
 GROUP BY Operator_Error;

 --Downtime operator error
 SELECT Factor_Name, Description, COUNT(Batch_ID) AS Frequency, SUM(Minutes) AS Delay_Mins FROM downtimeS
 JOIN downtime_factors ON downtimeS.Factor_ID=downtime_factors.Factor_ID
 WHERE Operator_Error = 1
 GROUP BY Factor_Name, Description
 ORDER BY sum(Minutes) DESC;

  --Downtime non operator error
 SELECT Factor_Name, Description, COUNT(Batch_ID) AS Frequency, SUM(Minutes) AS Delay_Mins FROM downtimeS
 JOIN downtime_factors ON downtimeS.Factor_ID=downtime_factors.Factor_ID
 WHERE Operator_Error = 0
 GROUP BY Factor_Name, Description
 ORDER BY sum(Minutes) DESC;

  --Products and Downtime frquency and delay (min)
  SELECT batch_pd.Product_ID, Product_Name, COUNT(downtimeS.Batch_ID) AS Frequency,SUM(Minutes) AS Delay_Mins FROM batch_pd
  JOIN downtimeS ON batch_pd.Batch_ID = downtimeS.Batch_ID
  JOIN products ON batch_pd.Product_ID = products.Product_ID
  GROUP BY batch_pd.Product_ID,Product_Name ORDER BY Frequency;

  -- How many factor are involved in each of the product downtime?
  SELECT batch_pd.Product_ID, Product_Name, COUNT(DISTINCT Factor_ID) AS Distinct_Factors FROM batch_pd
  JOIN products ON batch_pd.Product_ID = products.Product_ID
  JOIN downtimeS ON batch_pd.Batch_ID = downtimeS.Batch_ID
  GROUP BY batch_pd.product_ID, Product_Name

  -- Top 5 factors for product 1 downtime
  SELECT TOP 5 Factor_name, SUM(MInutes) AS Prd001_Delay_Mins FROM downtimeS
  JOIN downtime_factors ON downtimeS.Factor_ID = downtime_factors.Factor_ID
  JOIN batch_pd ON batch_pd.Batch_ID = downtimeS.Batch_ID
  WHERE Product_ID = 'PRD001'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC 


  -- Top 5 factors for product 2 downtime
  SELECT TOP 5 Factor_name, SUM(MInutes) AS Prd002_Delay_Mins FROM downtimeS
  JOIN downtime_factors ON downtimeS.Factor_ID = downtime_factors.Factor_ID
  JOIN batch_pd ON batch_pd.Batch_ID = downtimeS.Batch_ID
  WHERE Product_ID = 'PRD002'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC 

  -- Top 5 factors for product 3 downtime
  SELECT TOP 5 Factor_name, SUM(MInutes) AS Prd003_Delay_Mins FROM downtimeS
  JOIN downtime_factors ON downtimeS.Factor_ID = downtime_factors.Factor_ID
  JOIN batch_pd ON batch_pd.Batch_ID = downtimeS.Batch_ID
  WHERE Product_ID = 'PRD003'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC 

  -- Top 5 factors for product 4 downtime
  SELECT TOP 5 Factor_name, SUM(MInutes) AS Prd004_Delay_Mins FROM downtimeS
  JOIN downtime_factors ON downtimeS.Factor_ID = downtime_factors.Factor_ID
  JOIN batch_pd ON batch_pd.Batch_ID = downtimeS.Batch_ID
  WHERE Product_ID = 'PRD004'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC 

  --Production Lead Operators
  SELECT Operator, COUNT(Batch_ID) AS Number_of_batches, COUNT(DISTINCT Product_ID) AS Number_of_Products
  FROM Batch_pd
  GROUP BY Operator

  --Production Lead operator and dowmtime duration, percentage delayed Batches
  SELECT Operator,
  COUNT(DISTINCT batch_pd.Batch_ID) AS Total_Baches,
  COUNT(DISTINCT downtimeS.Batch_ID) AS Number_of_delayed_batches,
  COUNT(downtimeS.Batch_ID) AS Number_of_downtimeS,
  SUM(Minutes) AS Delay_Mins,
  CAST((COUNT(DISTINCT downtimeS.Batch_ID)*100.0)/(COUNT(DISTINCT batch_pd.Batch_ID)) AS DECIMAL (10,2))
  AS Percentage_delayed_batches
  FROM batch_pd
  LEFT JOIN downtimeS ON batch_pd.Batch_ID = downtimeS.Batch_ID
  GROUP BY Operator
  ORDER BY Percentage_delayed_batches DESC


  --Factors causing downtime for top 3 lead operators with most duration
  --1. Paul
  SELECT Factor_name, SUM(Minutes) AS Delay_Mins FROM downtime_factors
  JOIN downtimeS ON downtime_factors.Factor_ID =downtimeS.Factor_ID
  JOIN batch_pd ON batch_PD.Batch_ID = downtimeS.Batch_ID
  WHERE Operator = 'Paul'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC;
   
  --2. James
  SELECT Factor_name, SUM(Minutes) AS Delay_Mins FROM downtime_factors
  JOIN downtimeS ON downtime_factors.Factor_ID =downtimeS.Factor_ID
  JOIN batch_pd ON batch_PD.Batch_ID = downtimeS.Batch_ID
  WHERE Operator = 'James'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC;

  --3. Emily
  SELECT Factor_name, SUM(Minutes) AS Delay_Mins FROM downtime_factors
  JOIN downtimeS ON downtime_factors.Factor_ID =downtimeS.Factor_ID
  JOIN batch_pd ON batch_PD.Batch_ID = downtimeS.Batch_ID
  WHERE Operator = 'Emily'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC;

  --factors causing dowmtime for the top 3 operators with the most percentage 
  --dealyed batches
  --1. Linda 
  SELECT Factor_name, SUM(Minutes) AS Delay_Mins FROM downtime_factors
  JOIN downtimeS ON downtime_factors.Factor_ID =downtimeS.Factor_ID
  JOIN batch_pd ON batch_PD.Batch_ID = downtimeS.Batch_ID
  WHERE Operator = 'Linda'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC;

  --2.Sophia
  SELECT Factor_name, SUM(Minutes) AS Delay_Mins FROM downtime_factors
  JOIN downtimeS ON downtime_factors.Factor_ID =downtimeS.Factor_ID
  JOIN batch_pd ON batch_PD.Batch_ID = downtimeS.Batch_ID
  WHERE Operator = 'Sophia'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC;

  --Rita
  SELECT Factor_name, SUM(Minutes) AS Delay_Mins FROM downtime_factors
  JOIN downtimeS ON downtime_factors.Factor_ID =downtimeS.Factor_ID
  JOIN batch_pd ON batch_PD.Batch_ID = downtimeS.Batch_ID
  WHERE Operator = 'Rita'
  GROUP BY Factor_Name
  ORDER BY SUM(Minutes) DESC;
   
 SELECT 
	A.Operator,
	A.Batch_ID AS Batch_1,
	B.Batch_ID AS Batch_2,
	A.Start_Time AS Batch_1_Start,
	B.Start_Time AS Batch_2_Start,
	A.End_Time AS Batch_1_End,
	B.End_Time AS Batch_2_End
FROM line_productivity_batches A
JOIN line_productivity_batches B
	ON A.Operator = B.Operator
	AND A.Batch_ID < B.Batch_ID
	AND A.Start_Time< B.End_Time
	AND B.Start_Time <A.End_Time
ORDER BY A.Operator, A.Start_Time


-- =====================================================
-- SECTION 5: OPERATOR SCHEDULING ANALYSIS
-- =====================================================
-- Objective:
-- Identify overlapping production batches assigned
-- to the same operator and investigate whether
-- scheduling overlaps are associated with downtime.
--
-- Key areas:
-- 1. Identify overlapping production batches
-- 2. Count distinct batches affected by overlaps
-- 3. Compare downtime between overlapping and
--    non-overlapping production batches
-- =====================================================

WITH OverlappingBatches AS (
    SELECT
        A.Batch_ID AS Batch_1,
        B.Batch_ID AS Batch_2
    FROM line_productivity_batches A
    JOIN line_productivity_batches B
        ON A.Operator = B.Operator
        AND A.Batch_ID < B.Batch_ID
        AND A.Start_Time < B.End_Time
        AND B.Start_Time < A.End_Time
)
SELECT COUNT(DISTINCT Batch_ID) AS Unique_Overlapping_Batches
FROM (
    SELECT Batch_1 AS Batch_ID FROM OverlappingBatches
    UNION
    SELECT Batch_2 AS Batch_ID FROM OverlappingBatches
) AS CombinedBatches;


WITH OverlappingBatches AS (
    SELECT A.Batch_ID AS Batch_ID
    FROM line_productivity_batches A
    JOIN line_productivity_batches B
        ON A.Operator = B.Operator
        AND A.Batch_ID <> B.Batch_ID
        AND A.Start_Time < B.End_Time
        AND B.Start_Time < A.End_Time
),
BatchDowntime AS (
    SELECT
        Batch_ID,
        SUM(Minutes) AS Total_Downtime_Minutes
    FROM downtimeS
    GROUP BY Batch_ID
),
BatchComparison AS (
    SELECT
        B.Batch_ID,
        CASE
            WHEN O.Batch_ID IS NOT NULL
                THEN 'Overlapping'
            ELSE 'Non-Overlapping'
        END AS Schedule_Type,
        COALESCE(D.Total_Downtime_Minutes, 0)
            AS Downtime_Minutes
    FROM line_productivity_batches B
    LEFT JOIN (
        SELECT DISTINCT Batch_ID
        FROM OverlappingBatches
    ) O ON B.Batch_ID = O.Batch_ID
    LEFT JOIN BatchDowntime D
        ON B.Batch_ID = D.Batch_ID
)
SELECT
    Schedule_Type,
    COUNT(*) AS Total_Batches,
    SUM(CASE WHEN Downtime_Minutes > 0
        THEN 1 ELSE 0 END) AS Batches_With_Downtime,
    CAST(AVG(CAST(Downtime_Minutes AS DECIMAL(10,2)))
        AS DECIMAL(10,2)) AS Avg_Downtime_Minutes,
    SUM(Downtime_Minutes) AS Total_Downtime_Minutes
FROM BatchComparison
GROUP BY Schedule_Type;


-- =====================================================
-- KEY FINDINGS
-- =====================================================
-- 27 overlapping batch pairs were identified.
-- 53 distinct production batches were involved
-- in scheduling overlaps.
--
-- Average downtime:
-- Non-overlapping batches: 48.84 minutes
-- Overlapping batches: 45.25 minutes
--
-- These results suggest that overlapping batches
-- did not have higher average downtime in this
-- dataset. Further investigation would be needed
-- to determine whether scheduling overlaps
-- contributed to operational inefficiencies.
-- =====================================================

