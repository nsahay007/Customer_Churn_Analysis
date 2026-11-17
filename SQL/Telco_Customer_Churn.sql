-- 1. Check the table columns and data types
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'customer_churn'
ORDER BY ordinal_position;

-- 2. Preview a few records
SELECT *
FROM public.customer_churn
LIMIT 10;

-- 3. Confirm the record count
SELECT COUNT(*) AS total_customers
FROM public.customer_churn;

-- 4. Check churn and retention counts
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END) AS retained_customers,
    COUNT(*) =
        SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)
        + SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END)
        AS counts_reconcile
FROM public.customer_churn;

-- 5. Check for missing values in important columns
SELECT COUNT(*) AS rows_with_missing_important_data
FROM public.customer_churn
WHERE customer_id IS NULL
   OR tenure IS NULL
   OR monthly_charges IS NULL
   OR total_charges IS NULL
   OR churn IS NULL
   OR tenure_band IS NULL
   OR churn_flag IS NULL;

-- 6. Check for duplicate customer IDs
SELECT customer_id, COUNT(*) AS number_of_records
FROM public.customer_churn
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 7. Check the zero-tenure records
SELECT
    COUNT(*) AS zero_tenure_customers,
    SUM(CASE WHEN total_charges = 0 THEN 1 ELSE 0 END) AS with_zero_total_charges
FROM public.customer_churn
WHERE tenure = 0;

-- 8. Check for any remaining blank TotalCharges
SELECT COUNT(*) AS missing_total_charges
FROM public.customer_churn
WHERE total_charges IS NULL;

-- 9. Check that each tenure band matches the customer’s tenure
SELECT COUNT(*) AS invalid_tenure_bands
FROM public.customer_churn
WHERE tenure IS NULL
   OR tenure_band IS NULL
   OR tenure_band <>
        CASE
            WHEN tenure BETWEEN 0 AND 12 THEN '0-12 Months'
            WHEN tenure BETWEEN 13 AND 24 THEN '13-24 Months'
            WHEN tenure BETWEEN 25 AND 48 THEN '25-48 Months'
            WHEN tenure >= 49 THEN '49+ Months'
            ELSE 'INVALID'
        END;

-- 10. Check that the churn flags match the churn values
SELECT COUNT(*) AS invalid_churn_flags
FROM public.customer_churn
WHERE churn IS NULL
   OR churn_flag IS NULL
   OR (churn = 'Yes' AND churn_flag <> 1)
   OR (churn = 'No' AND churn_flag <> 0)
   OR churn NOT IN ('Yes', 'No');

-- 11. Calculate the KPI summary
SELECT
    COUNT(*) AS total_customers,

    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)
        AS churned_customers,

    SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END)
        AS retained_customers,

    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent,

    ROUND(
        100.0 * SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS retention_rate_percent,

    ROUND(AVG(monthly_charges), 2)
        AS average_monthly_charges,

    ROUND(
        AVG(CASE WHEN churn = 'Yes' THEN monthly_charges END),
        2
    ) AS average_monthly_charges_churned,

    ROUND(
        AVG(CASE WHEN churn = 'No' THEN monthly_charges END),
        2
    ) AS average_monthly_charges_retained,

    ROUND(
        SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END),
        2
    ) AS monthly_revenue_at_risk
FROM public.customer_churn;

-- 12. Churn by contract type
SELECT
    contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY contract
ORDER BY contract;

-- 13. Churn by tenure band
SELECT
    tenure_band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS retention_rate_percent
FROM public.customer_churn
GROUP BY tenure_band
ORDER BY tenure_band;

-- 14. Churn by payment method
SELECT
    payment_method,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY payment_method
ORDER BY payment_method;

-- 15. Churn by internet service
SELECT
    internet_service,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY internet_service
ORDER BY internet_service;

-- 16. Compare monthly charges for churned and retained customers
SELECT
    churn,
    COUNT(*) AS customer_count,
    ROUND(AVG(monthly_charges), 2) AS average_monthly_charges
FROM public.customer_churn
GROUP BY churn
ORDER BY churn;

-- 17. Monthly revenue at risk by contract
SELECT
    contract,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)
        AS churned_customers,
    ROUND(
        SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END),
        2
    ) AS monthly_revenue_at_risk
FROM public.customer_churn
GROUP BY contract
ORDER BY contract;

-- 18. Churn by customer gender
SELECT
    gender,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY gender
ORDER BY gender;

-- 19. Churn by senior-citizen status
SELECT
    senior_citizen,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY senior_citizen
ORDER BY senior_citizen;

-- 20. Churn by partner status
SELECT
    partner,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY partner
ORDER BY partner;

-- 21. Churn by dependents status
SELECT
    dependents,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY dependents
ORDER BY dependents;

-- 22. Churn by paperless billing status
SELECT
    paperless_billing,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY paperless_billing
ORDER BY paperless_billing;

-- 23. Churn by online security
SELECT
    online_security,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY online_security
ORDER BY online_security;

-- 24. Churn by tech support
SELECT
    tech_support,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM public.customer_churn
GROUP BY tech_support
ORDER BY tech_support;