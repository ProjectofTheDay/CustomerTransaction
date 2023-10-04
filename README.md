
# Cohort Analysis based on Customer Transaction

## Project Explanation
**Problem**: A store wants to determine the percentage of customers who make repeat purchases in the following month while selling its products in 2022. This value will be used for evaluation and improvement in the following year.

**Problem-solving**: The first approach is to conduct time-based cohort analysis. Time-based cohort analysis is a type of analysis that categorizes individuals based on the time when they initially became customers or users. From this cohort analysis, you can then derive a Retention Rate, which can be used as a metric to measure how effectively the company can encourage customers to make repeated purchases of its products.


## Feature
**Dataset**: The dataset used is CustomerPayment, and CustomerRetention is the outcome of the SQL query used for data visualization.


**Tools**: SQL Server for analysis and visualize the results through Tableau.


## Analysis Approach
### 1. Extract Columns Needed
To conduct a time-based cohort analysis, what's needed is the initial date when the customer made their first transaction.

```sql
SELECT 
  customer_id,
  MIN(transaction_date) as FirstDate,
  DATEFROMPARTS(YEAR(MIN(transaction_date)), MONTH(MIN(transaction_date)), 1) as FirstTransaction
INTO #cohort
FROM CustomerPayment
GROUP BY customer_id
```


### 2. Make Cohort Index
The query result then inserted into a temporary table named Cohort. Within the Cohort table, then I could subsequently create a cohort index.

```sql
SELECT 
  cust.*,
  cr.FirstTransaction,
  YEAR(cust.transaction_date) as transaction_year,
  MONTH(cust.transaction_date) as transaction_month,
  YEAR(cr.FirstTransaction) as cohort_year,
  MONTH(cr.FirstTransaction) as cohort_month
FROM CustomerPayment as cust
LEFT JOIN #cohort as cr
  ON cust.customer_id = cr.customer_id 
```
Because for the cohort index, only the year and month of purchase are needed. Therefore, the first step is to extract the year and month of the purchase transaction, as well as the year and month of the first transaction.


```sql
SELECT 
  ci.*,
  year_diff = transaction_year - cohort_year,
  month_diff = transaction_month - cohort_month
FROM 
  (
  SELECT 
    cust.*,
    cr.FirstTransaction,
    YEAR(cust.transaction_date) as transaction_year,
    MONTH(cust.transaction_date) as transaction_month,
    YEAR(cr.FirstTransaction) as cohort_year,
    MONTH(cr.FirstTransaction) as cohort_month
  FROM CustomerPayment as cust
  LEFT JOIN #cohort as cr
    ON cust.customer_id = cr.customer_id 
  ) ci
```
The difference obtained can be used to calculate the cohort index using the formula that increases the index for each purchase made in the following month.


```sql
SELECT 
  cin.*,
  cohort_index = year_diff * 12 + month_diff + 1
INTO #retention
FROM 
  (
  SELECT
    ci.*,
    year_diff = transaction_year - cohort_year,
    month_diff = transaction_month - cohort_month
  FROM 
    (
    SELECT
      cust.*,
      cr.FirstTransaction,
      YEAR(cust.transaction_date) as transaction_year,
      MONTH(cust.transaction_date) as transaction_month,
      YEAR(cr.FirstTransaction) as cohort_year,
      MONTH(cr.FirstTransaction) as cohort_month
    FROM CustomerPayment as cust
    LEFT JOIN #cohort as cr
      ON cust.customer_id = cr.customer_id 
    ) ci
  ) cin
```

The obtained cohort index is then utilized to calculate customer retention on a monthly basis throughout the year 2022.

### 3. Measure Retention Rate
First, pivot table is made to see the cohort table.

```sql
SELECT *
INTO #cohortpivot
FROM
  (
  SELECT DISTINCT
    customer_id,
    FirstTransaction,
    cohort_index
  FROM #retention 
  ) p
  PIVOT
  (
  COUNT(customer_id)
  FOR cohort_index IN
    (
    [1],
    [2],
    [3],
    [4],
    [5],
    [6],
    [7],
    [8],
    [9],
    [10],
    [11],
    [12]
    )
  )AS pt
```

Customer retention is accumulated by referencing the number of customers who made their initial transactions and then increasing their index value each time they make a transaction in the following month.

```sql
SELECT *
FROM #cohortpivot
ORDER BY FirstTransaction
```

Result: <br>
<a href="https://drive.google.com/uc?export=view&id=10KJse5FHtXmmUGMcLBF6zS3EMOVaW0iP"><img src="https://drive.google.com/uc?export=view&id=10KJse5FHtXmmUGMcLBF6zS3EMOVaW0iP" title="Click for the larger version." /></a>


From the results obtained, only 30% of customers make a second purchase, but for the next purchases after the second purchase, the number of customers making repeat purchases can be considered quite good as there is no significant decline, and it remains substantial.


## Dashboard
![alt text](https://github.com/ProjectofTheDay/CustomerTransaction/blob/main/MoM%20Retention%20Rate.png?raw=true)

The interactive dashboard could be seen [here](https://public.tableau.com/views/RetentionRateofCustomerTransaction/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link). 
