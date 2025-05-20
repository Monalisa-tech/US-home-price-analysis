# US-home-price-analysis
# US Housing Trends: 20-Year Insight

## Objective

This project aims to analyze how key macroeconomic factors have influenced U.S. home prices over the past 20 years. Using publicly available datasets and SQL Server for modeling, the analysis identifies correlations and builds a regression model to explain housing price trends. Tableau was used to visualize the results in a clean, interactive dashboard.

---

## Data Sources

All datasets were sourced from publicly available U.S. economic indicators:

- **Home Price Index (CSUSHPISA)** – S&P/Case-Shiller Index via [FRED](https://fred.stlouisfed.org)
- **Mortgage Rate (MORTGAGE30US)** – 30-Year Fixed Mortgage Rate via FRED
- **Median Household Income (MEHOINUSA672N)** – U.S. Census Bureau via FRED
- **Unemployment Rate (UNRATE)** – Bureau of Labor Statistics via FRED
- **GDP (GDPC1)** – Real Gross Domestic Product via FRED
- **Housing Starts (HOUST)** – U.S. Census Bureau via FRED
- **Inflation (CPIAUCSL)** – Consumer Price Index via FRED
- **Population (POPTHM)** – Monthly U.S. Population Estimates via FRED

---

##  Key Steps Taken

### 1. **Database Setup and Data Loading (SQL Server)**:
- Created 8 individual tables for each macroeconomic factor using `BULK INSERT`.
- Cleaned, transformed, and converted all data to **monthly frequency**.
- Forward filled missing or sparse data (e.g., annual/quarterly data like GDP, income).

### 2. **Data Integration**:
- Created a centralized `Master_Joined_Data` table by joining all datasets on a generated monthly calendar (`observation_month`).

### 3. **Data Cleaning & Preparation**:
- Created `Cleaned_Model_Data` after handling missing values and aligning time granularity.
- Ensured full monthly continuity from Jan 2005 to Apr 2025.

### 4. **Analysis**:
- **Correlation Analysis**: Computed Pearson correlations between Home Price Index (HPI) and each macroeconomic factor.
- **Linear Regression Modeling**: 
    - Built multiple regression models using SQL (OLS method).
    - Regression Equation:
      ```
      HomePriceIndex = -879.94 
                       + 11.15 * MortgageRate 
                       + 0.0094 * MedianIncome 
                       - 17.42 * UnemploymentRate 
                       + 0.0233 * GDP
      ```

### 5. **Visualization in Tableau**:
- Created a professional Tableau dashboard showing:
  - HPI trend over 20 years
  - Factor relationships (scatter plots)
  - Regression coefficient contributions
  - Correlation strength across variables
  - Summary KPIs

---

##  Summary of Findings

- **GDP** is the **strongest positive driver** of home prices (Correlation: 0.91).
- **Unemployment Rate** has a **moderate negative impact** (Correlation: -0.606, Regression Beta: -17.42).
- **Home Price Index** (HPI) grew **over 102%** in 20 years.
- Mortgage Rate also positively contributes, though with more variation.
- Overall, economic growth and employment stability are closely tied to housing affordability and appreciation.

---

## 🔗 Tableau Dashboard

👉 **[View Tableau Dashboard](https://public.tableau.com/views/Home_Price_DS_Model/USHousingTrends20-YearInsight?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**  
*Replace the above link with your actual Tableau Public link.*

---

## Tools Used

- **SQL Server 2019** – ETL, cleaning, modeling, and regression
- **Tableau Public** – Visualization & dashboarding
- **Excel** – Initial data exploration & manual CSV editing (optional)

---

## Next Steps

- Incorporate time-series models like ARIMA or LSTM in Python for price forecasting.
- Add regional-level analysis (state/city level HPI).
- Include policy indicators (interest rate, housing subsidies) in future models.

---

##  Author

**Monalisa Behera**  
📧 Email: [mbehera95@gmail.com]  
🌐 [LinkedIn](https://www.linkedin.com/in/monalisa-behera-66b802108/) | [GitHub](https://github.com/Monalisa-tech) | [Kaggle](https://www.kaggle.com/monalisahansika)

---

