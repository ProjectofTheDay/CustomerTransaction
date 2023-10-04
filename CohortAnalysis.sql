SELECT *
FROM CustomerPayment

--For time-based cohort analysis
--The first transaction's date of one customer is needed
SELECT 
	customer_id,
	MIN(transaction_date) as FirstDate,
	DATEFROMPARTS(YEAR(MIN(transaction_date)), MONTH(MIN(transaction_date)), 1) as FirstTransaction
INTO #cohort
FROM CustomerPayment
GROUP BY customer_id

--Cohort index
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

--Make cohort table by pivot data
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
	PIVOT (
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


SELECT *
FROM #cohortpivot
ORDER BY FirstTransaction

--Create the percentage of how much customer make transaction again
SELECT	FirstTransaction,
		1.0*[1]/[1]*100 AS [1],
		1.0*[2]/[1]*100 AS [2],
		1.0*[3]/[1]*100 AS [3],
		1.0*[4]/[1]*100 AS [4],
		1.0*[5]/[1]*100 AS [5],
		1.0*[6]/[1]*100 AS [6],
		1.0*[7]/[1]*100 AS [7],
		1.0*[8]/[1]*100 AS [8],
		1.0*[9]/[1]*100 AS [9],
		1.0*[10]/[1]*100 AS [10],
		1.0*[11]/[1]*100 AS [11],
		1.0*[11]/[1]*100 AS [12]
FROM #cohortpivot
ORDER BY FirstTransaction