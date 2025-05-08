Create database Home_Project      
use Home_Project

------Table1: HomePriceIndex----

CREATE TABLE HomePriceIndex (
    observation_date DATE PRIMARY KEY,
    CSUSHPISA FLOAT 
);

BULK INSERT HomePriceIndex
FROM 'C:\Users\USER\Documents\CSUSHPISA.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FORMAT = 'CSV'
);

select*from HomePriceIndex

-----Table2: MortgageRate----

CREATE TABLE MortgageRate_Staging (
    observation_date VARCHAR(20),
    MORTGAGE30US FLOAT
);

BULK INSERT MortgageRate_Staging
FROM 'C:\Users\USER\Documents\MORTGAGE30US.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

CREATE TABLE MortgageRate (
    observation_date DATE PRIMARY KEY,
    MORTGAGE30US FLOAT
);

INSERT INTO MortgageRate (observation_date, MORTGAGE30US)
SELECT 
    CONVERT(DATE, observation_date, 105),  -- 105 = dd-mm-yyyy
    MORTGAGE30US
FROM MortgageRate_Staging;


SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MortgageRate';

select*from MortgageRate


----Table3:MedianIncome-----

CREATE TABLE MedianIncome(
    observation_date DATE PRIMARY KEY,
    MEHOINUSA672N  int
);

BULK INSERT MedianIncome
FROM 'C:\Users\USER\Documents\MEHOINUSA672N.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);



SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MedianIncome';

select*from  MedianIncome


-----Table4:UnemploymentRate-----

CREATE TABLE UnemploymentRate (
    observation_date DATE PRIMARY KEY,
    UNRATE DECIMAL(4,1)
);

BULK INSERT UnemploymentRate
FROM 'C:\Users\USER\Documents\UNRATE.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'UnemploymentRate';


select*from  UnemploymentRate

-----Table5:HousingStarts---

CREATE TABLE HousingStarts (
    observation_date DATE PRIMARY KEY,
    HOUST int
);

BULK INSERT HousingStarts 
FROM 'C:\Users\USER\Documents\HOUST.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

select*from HousingStarts


-----Table6:InflationCPI------

CREATE TABLE InflationCPI (
    observation_date DATE PRIMARY KEY,
    CPIAUCSL DECIMAL(7,3)
);

BULK INSERT InflationCPI
FROM 'C:\Users\USER\Documents\CPIAUCSL.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

select*from InflationCPI


------ Table7:GDP-----

CREATE TABLE GDP (
    observation_date DATE PRIMARY KEY,
    GDPC1 DECIMAL(10,3)
);


BULK INSERT GDP
FROM 'C:\Users\USER\Documents\GDPC1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

Select*from GDP


----Table8:  Population-----

CREATE TABLE Population (
    observation_date DATE PRIMARY KEY,
    POPTHM int
);


BULK INSERT Population
FROM 'C:\Users\USER\Documents\POPTHM.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

select*from Population


-----Checking all datatypes valid or not----
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-----Clean unwanted table data---
DROP TABLE MortgageRate_Staging;





----Mortgage Rate (Weekly → Monthly Average)---

SELECT 
    FORMAT(observation_date, 'yyyy-MM-01') AS observation_month,
    AVG(MORTGAGE30US) AS MonthlyMortgageRate
INTO MortgageRate_Monthly
FROM MortgageRate
GROUP BY FORMAT(observation_date, 'yyyy-MM-01');


-----GDP (Quarterly → Forward Fill Monthly)---

SELECT 
    FORMAT(observation_date, 'yyyy-MM-01') AS observation_month,
    GDPC1
INTO GDP_Monthly
FROM GDP;


----Median Income (Yearly → Fill for Each Month in Year)----

SELECT 
    DATEFROMPARTS(YEAR(observation_date), m.number, 1) AS observation_month,
    MEHOINUSA672N
INTO MedianIncome_Monthly
FROM MedianIncome
CROSS JOIN master.dbo.spt_values m
WHERE m.type = 'P' AND m.number BETWEEN 1 AND 12;


-----Other Monthly Tables (Just Standardize Date)----

-- HomePriceIndex
SELECT 
    FORMAT(observation_date, 'yyyy-MM-01') AS observation_month,
    CSUSHPISA AS HomePriceIndex
INTO HomePriceIndex_Monthly
FROM HomePriceIndex;

-- UnemploymentRate
SELECT 
    FORMAT(observation_date, 'yyyy-MM-01') AS observation_month,
    UNRATE AS UnemploymentRate
INTO UnemploymentRate_Monthly
FROM UnemploymentRate;

-- HousingStarts
SELECT 
    FORMAT(observation_date, 'yyyy-MM-01') AS observation_month,
    HOUST AS HousingStarts
INTO HousingStarts_Monthly
FROM HousingStarts;

-- InflationCPI
SELECT 
    FORMAT(observation_date, 'yyyy-MM-01') AS observation_month,
    CPIAUCSL AS InflationCPI
INTO InflationCPI_Monthly
FROM InflationCPI;

-- Population
SELECT 
    FORMAT(observation_date, 'yyyy-MM-01') AS observation_month,
    POPTHM AS Population
INTO Population_Monthly
FROM Population;


-- Create Monthly Calendar Table---

WITH MonthSequence AS (
    SELECT CAST('2005-01-01' AS DATE) AS observation_month
    UNION ALL
    SELECT DATEADD(MONTH, 1, observation_month)
    FROM MonthSequence
    WHERE observation_month < EOMONTH(GETDATE())
)
SELECT observation_month
INTO MonthlyCalendar
FROM MonthSequence
OPTION (MAXRECURSION 32767);



----//Create Master Joined Table//---


SELECT  
    cal.observation_month,
    hpi.HomePriceIndex,
    mr.MonthlyMortgageRate,
    mi.MEHOINUSA672N AS MedianIncome,
    ur.UnemploymentRate,
    hs.HousingStarts,
    cpi.InflationCPI,
    gdp.GDPC1 AS GDP,
    pop.Population
INTO Master_Joined_Data
FROM MonthlyCalendar cal
LEFT JOIN HomePriceIndex_Monthly hpi    ON cal.observation_month = hpi.observation_month
LEFT JOIN MortgageRate_Monthly mr       ON cal.observation_month = mr.observation_month
LEFT JOIN MedianIncome_Monthly mi       ON cal.observation_month = mi.observation_month
LEFT JOIN UnemploymentRate_Monthly ur   ON cal.observation_month = ur.observation_month
LEFT JOIN HousingStarts_Monthly hs      ON cal.observation_month = hs.observation_month
LEFT JOIN InflationCPI_Monthly cpi      ON cal.observation_month = cpi.observation_month
LEFT JOIN GDP_Monthly gdp               ON cal.observation_month = gdp.observation_month
LEFT JOIN Population_Monthly pop        ON cal.observation_month = pop.observation_month;



SELECT *
FROM Master_Joined_Data
ORDER BY observation_month;


SELECT *
FROM Master_Joined_Data
WHERE 
    HomePriceIndex IS NULL OR
    MonthlyMortgageRate IS NULL OR
    MedianIncome IS NULL OR
    UnemploymentRate IS NULL OR
    HousingStarts IS NULL OR
    InflationCPI IS NULL OR
    GDP IS NULL OR
    Population IS NULL
ORDER BY observation_month;



----Create Forward-Filled Table----

SELECT
    observation_month,
    
    -- Forward Fill HomePriceIndex
    FIRST_VALUE(HomePriceIndex) OVER (
        PARTITION BY grp_HPI ORDER BY observation_month
    ) AS HomePriceIndex,
    
    -- Forward Fill MortgageRate
    FIRST_VALUE(MonthlyMortgageRate) OVER (
        PARTITION BY grp_MortgageRate ORDER BY observation_month
    ) AS MonthlyMortgageRate,
    
    -- Forward Fill MedianIncome
    FIRST_VALUE(MedianIncome) OVER (
        PARTITION BY grp_MedianIncome ORDER BY observation_month
    ) AS MedianIncome,
    
    -- Forward Fill UnemploymentRate
    FIRST_VALUE(UnemploymentRate) OVER (
        PARTITION BY grp_UnemploymentRate ORDER BY observation_month
    ) AS UnemploymentRate,
    
    -- Forward Fill HousingStarts
    FIRST_VALUE(HousingStarts) OVER (
        PARTITION BY grp_HousingStarts ORDER BY observation_month
    ) AS HousingStarts,
    
    -- Forward Fill InflationCPI
    FIRST_VALUE(InflationCPI) OVER (
        PARTITION BY grp_InflationCPI ORDER BY observation_month
    ) AS InflationCPI,
    
    -- Forward Fill GDP
    FIRST_VALUE(GDP) OVER (
        PARTITION BY grp_GDP ORDER BY observation_month
    ) AS GDP,
    
    -- Forward Fill Population
    FIRST_VALUE(Population) OVER (
        PARTITION BY grp_Population ORDER BY observation_month
    ) AS Population

INTO Cleaned_Model_Data
FROM (
    SELECT *,
    
        -- Create group numbers for forward fill
        SUM(CASE WHEN HomePriceIndex IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_HPI,
        SUM(CASE WHEN MonthlyMortgageRate IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_MortgageRate,
        SUM(CASE WHEN MedianIncome IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_MedianIncome,
        SUM(CASE WHEN UnemploymentRate IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_UnemploymentRate,
        SUM(CASE WHEN HousingStarts IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_HousingStarts,
        SUM(CASE WHEN InflationCPI IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_InflationCPI,
        SUM(CASE WHEN GDP IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_GDP,
        SUM(CASE WHEN Population IS NOT NULL THEN 1 ELSE 0 END) OVER (ORDER BY observation_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_Population

    FROM Master_Joined_Data
) sub;


SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN HomePriceIndex IS NULL THEN 1 ELSE 0 END) AS Null_HomePriceIndex,
    SUM(CASE WHEN MonthlyMortgageRate IS NULL THEN 1 ELSE 0 END) AS Null_MonthlyMortgageRate,
    SUM(CASE WHEN MedianIncome IS NULL THEN 1 ELSE 0 END) AS Null_MedianIncome,
    SUM(CASE WHEN UnemploymentRate IS NULL THEN 1 ELSE 0 END) AS Null_UnemploymentRate,
    SUM(CASE WHEN HousingStarts IS NULL THEN 1 ELSE 0 END) AS Null_HousingStarts,
    SUM(CASE WHEN InflationCPI IS NULL THEN 1 ELSE 0 END) AS Null_InflationCPI,
    SUM(CASE WHEN GDP IS NULL THEN 1 ELSE 0 END) AS Null_GDP,
    SUM(CASE WHEN Population IS NULL THEN 1 ELSE 0 END) AS Null_Population
FROM Cleaned_Model_Data;





-----Correlation Analysis (All 8 Variables)----

--  Correlation between HomePriceIndex and each factor----

WITH FactorAverages AS (
    SELECT 
        AVG(HomePriceIndex) AS HPI_Avg,
        AVG(MonthlyMortgageRate) AS MMR_Avg,
        AVG(MedianIncome) AS MI_Avg,
        AVG(UnemploymentRate) AS UR_Avg,
        AVG(HousingStarts) AS HS_Avg,
        AVG(InflationCPI) AS CPI_Avg,
        AVG(Population) AS Pop_Avg,
        AVG(GDP) AS GDP_Avg
    FROM Cleaned_Model_Data
)
SELECT
    'MonthlyMortgageRate' AS Factor,
    SUM(CAST((HomePriceIndex - HPI_Avg) * (MonthlyMortgageRate - MMR_Avg) AS FLOAT)) /
    (SQRT(SUM(CAST(POWER(HomePriceIndex - HPI_Avg, 2) AS FLOAT))) * SQRT(SUM(CAST(POWER(MonthlyMortgageRate - MMR_Avg, 2) AS FLOAT)))) AS Correlation
FROM Cleaned_Model_Data, FactorAverages
UNION ALL
SELECT
    'MedianIncome' AS Factor,
    SUM(CAST((HomePriceIndex - HPI_Avg) * (MedianIncome - MI_Avg) AS FLOAT)) /
    (SQRT(SUM(CAST(POWER(HomePriceIndex - HPI_Avg, 2) AS FLOAT))) * SQRT(SUM(CAST(POWER(MedianIncome - MI_Avg, 2) AS FLOAT)))) AS Correlation
FROM Cleaned_Model_Data, FactorAverages
UNION ALL
SELECT
    'UnemploymentRate' AS Factor,
    SUM(CAST((HomePriceIndex - HPI_Avg) * (UnemploymentRate - UR_Avg) AS FLOAT)) /
    (SQRT(SUM(CAST(POWER(HomePriceIndex - HPI_Avg, 2) AS FLOAT))) * SQRT(SUM(CAST(POWER(UnemploymentRate - UR_Avg, 2) AS FLOAT)))) AS Correlation
FROM Cleaned_Model_Data, FactorAverages
UNION ALL
SELECT
    'HousingStarts' AS Factor,
    SUM(CAST((HomePriceIndex - HPI_Avg) * (HousingStarts - HS_Avg) AS FLOAT)) /
    (SQRT(SUM(CAST(POWER(HomePriceIndex - HPI_Avg, 2) AS FLOAT))) * SQRT(SUM(CAST(POWER(HousingStarts - HS_Avg, 2) AS FLOAT)))) AS Correlation
FROM Cleaned_Model_Data, FactorAverages
UNION ALL
SELECT
    'InflationCPI' AS Factor,
    SUM(CAST((HomePriceIndex - HPI_Avg) * (InflationCPI - CPI_Avg) AS FLOAT)) /
    (SQRT(SUM(CAST(POWER(HomePriceIndex - HPI_Avg, 2) AS FLOAT))) * SQRT(SUM(CAST(POWER(InflationCPI - CPI_Avg, 2) AS FLOAT)))) AS Correlation
FROM Cleaned_Model_Data, FactorAverages
UNION ALL
SELECT
    'Population' AS Factor,
    SUM(CAST((HomePriceIndex - HPI_Avg) * (Population - Pop_Avg) AS FLOAT)) /
    (SQRT(SUM(CAST(POWER(HomePriceIndex - HPI_Avg, 2) AS FLOAT))) * SQRT(SUM(CAST(POWER(Population - Pop_Avg, 2) AS FLOAT)))) AS Correlation
FROM Cleaned_Model_Data, FactorAverages
UNION ALL
SELECT
    'GDP' AS Factor,
    SUM(CAST((HomePriceIndex - HPI_Avg) * (GDP - GDP_Avg) AS FLOAT)) /
    (SQRT(SUM(CAST(POWER(HomePriceIndex - HPI_Avg, 2) AS FLOAT))) * SQRT(SUM(CAST(POWER(GDP - GDP_Avg, 2) AS FLOAT)))) AS Correlation
FROM Cleaned_Model_Data, FactorAverages;


----- Prepare Model_Regression_Means Model---


SELECT *
INTO Model_Regression_Input
FROM Cleaned_Model_Data
WHERE HomePriceIndex IS NOT NULL
  AND MonthlyMortgageRate IS NOT NULL
  AND MedianIncome IS NOT NULL
  AND UnemploymentRate IS NOT NULL
  AND GDP IS NOT NULL;

 --- Calculate means of all variables

  SELECT 
    AVG(CAST(HomePriceIndex AS FLOAT)) AS HPI_Avg,
    AVG(CAST(MonthlyMortgageRate AS FLOAT)) AS MMR_Avg,
    AVG(CAST(MedianIncome AS FLOAT)) AS MI_Avg,
    AVG(CAST(UnemploymentRate AS FLOAT)) AS UR_Avg,
    AVG(CAST(GDP AS FLOAT)) AS GDP_Avg
INTO Model_Regression_Means
FROM Model_Regression_Input;


---Compute covariance and variances needed for regression

SELECT 
    SUM((MonthlyMortgageRate - MMR_Avg) * (HomePriceIndex - HPI_Avg)) AS Cov_MMR_HPI,
    SUM((MedianIncome - MI_Avg) * (HomePriceIndex - HPI_Avg)) AS Cov_MI_HPI,
    SUM((UnemploymentRate - UR_Avg) * (HomePriceIndex - HPI_Avg)) AS Cov_UR_HPI,
    SUM((GDP - GDP_Avg) * (HomePriceIndex - HPI_Avg)) AS Cov_GDP_HPI,

    SUM(POWER(MonthlyMortgageRate - MMR_Avg, 2)) AS Var_MMR,
    SUM(POWER(MedianIncome - MI_Avg, 2)) AS Var_MI,
    SUM(POWER(UnemploymentRate - UR_Avg, 2)) AS Var_UR,
    SUM(POWER(GDP - GDP_Avg, 2)) AS Var_GDP
FROM Model_Regression_Input, Model_Regression_Means;


----Compute β coefficients (basic OLS)

SELECT 
    (SUM((MonthlyMortgageRate - MMR_Avg) * (HomePriceIndex - HPI_Avg)) / 
     SUM(POWER(MonthlyMortgageRate - MMR_Avg, 2))) AS Beta_MMR
FROM Model_Regression_Input, Model_Regression_Means;


SELECT 
    -- Beta for MonthlyMortgageRate
    SUM((MonthlyMortgageRate - MMR_Avg) * (HomePriceIndex - HPI_Avg)) / 
        NULLIF(SUM(POWER(MonthlyMortgageRate - MMR_Avg, 2)), 0) AS Beta_MMR,

    -- Beta for MedianIncome
    SUM((MedianIncome - MI_Avg) * (HomePriceIndex - HPI_Avg)) / 
        NULLIF(SUM(POWER(MedianIncome - MI_Avg, 2)), 0) AS Beta_MI,

    -- Beta for UnemploymentRate
    SUM((UnemploymentRate - UR_Avg) * (HomePriceIndex - HPI_Avg)) / 
        NULLIF(SUM(POWER(UnemploymentRate - UR_Avg, 2)), 0) AS Beta_UR,

    -- Beta for GDP
    SUM((GDP - GDP_Avg) * (HomePriceIndex - HPI_Avg)) / 
        NULLIF(SUM(POWER(GDP - GDP_Avg, 2)), 0) AS Beta_GDP

FROM Model_Regression_Input, Model_Regression_Means;



----Multiple linear regression (coefficients β₀ to β₄)------


-- Step 1: Compute Means
WITH Means AS (
    SELECT
        AVG(CAST(HomePriceIndex AS FLOAT)) AS HPI_Avg,
        AVG(CAST(MonthlyMortgageRate AS FLOAT)) AS MMR_Avg,
        AVG(CAST(MedianIncome AS FLOAT)) AS MI_Avg,
        AVG(CAST(UnemploymentRate AS FLOAT)) AS UR_Avg,
        AVG(CAST(GDP AS FLOAT)) AS GDP_Avg
    FROM Cleaned_Model_Data
),

-- Step 2: Compute Regression Coefficients
Betas AS (
    SELECT 
        SUM((CAST(MonthlyMortgageRate AS FLOAT) - m.MMR_Avg) * 
            (CAST(HomePriceIndex AS FLOAT) - m.HPI_Avg)) / 
            NULLIF(SUM(POWER(CAST(MonthlyMortgageRate AS FLOAT) - m.MMR_Avg, 2)), 0) AS Beta_MMR,

        SUM((CAST(MedianIncome AS FLOAT) - m.MI_Avg) * 
            (CAST(HomePriceIndex AS FLOAT) - m.HPI_Avg)) / 
            NULLIF(SUM(POWER(CAST(MedianIncome AS FLOAT) - m.MI_Avg, 2)), 0) AS Beta_MI,

        SUM((CAST(UnemploymentRate AS FLOAT) - m.UR_Avg) * 
            (CAST(HomePriceIndex AS FLOAT) - m.HPI_Avg)) / 
            NULLIF(SUM(POWER(CAST(UnemploymentRate AS FLOAT) - m.UR_Avg, 2)), 0) AS Beta_UR,

        SUM((CAST(GDP AS FLOAT) - m.GDP_Avg) * 
            (CAST(HomePriceIndex AS FLOAT) - m.HPI_Avg)) / 
            NULLIF(SUM(POWER(CAST(GDP AS FLOAT) - m.GDP_Avg, 2)), 0) AS Beta_GDP

    FROM Cleaned_Model_Data d
    CROSS JOIN Means m
),

-- Step 3: Compute Intercept
InterceptCalc AS (
    SELECT 
        m.HPI_Avg 
        - (b.Beta_MMR * m.MMR_Avg) 
        - (b.Beta_MI * m.MI_Avg) 
        - (b.Beta_UR * m.UR_Avg) 
        - (b.Beta_GDP * m.GDP_Avg) AS Intercept,
        b.*
    FROM Means m, Betas b
)

-- Final Output
SELECT * FROM InterceptCalc;



-----Interpretation of Results---

---*//Regression Equation:HomePriceIndex=−879.94+11.15⋅MortgageRate+0.0094⋅MedianIncome−17.42⋅UnemploymentRate+0.0233⋅GDP//*


SELECT * FROM Cleaned_Model_Data;


------HPI increased over 20 years----

WITH HPI_Bounds AS (
    SELECT 
        MIN(observation_month) AS StartMonth,
        MAX(observation_month) AS EndMonth
    FROM Cleaned_Model_Data
),
HPI_Values AS (
    SELECT 
        (SELECT TOP 1 HomePriceIndex 
         FROM Cleaned_Model_Data
         ORDER BY observation_month ASC) AS Initial_HPI,
        (SELECT TOP 1 HomePriceIndex 
         FROM Cleaned_Model_Data
         ORDER BY observation_month DESC) AS Final_HPI
)
SELECT 
    Initial_HPI,
    Final_HPI,
    ROUND(((Final_HPI - Initial_HPI) * 100.0) / Initial_HPI, 2) AS HPI_Growth_Percentage
FROM 
    HPI_Values;





	CREATE VIEW KPI_Summary_Cards AS
SELECT 'GDP has the strongest correlation' AS KPI_Label, 'Correlation: 0.910' AS KPI_Value
UNION ALL
SELECT 'Unemployment has a moderate negative impact', 'Correlation: -0.606'
UNION ALL
SELECT 'HPI increased over 20 years', 'Growth: +102.18%';

select*from KPI_Summary_Cards
































 














