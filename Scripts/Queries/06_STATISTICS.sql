-- All this functiona will be used in "Estadisticas".

/*
 * The fucntion stats_users_by_age_ranges will return the total number of users 
 * grouped by age ranges.
 */

CREATE OR REPLACE FUNCTION public.stats_users_by_age_ranges(
  p_ref_date date DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  age_range text,
  user_count bigint
)
LANGUAGE sql
AS $$
SELECT
  CASE
    WHEN age_years BETWEEN 0 AND 18 THEN '0-18'
    WHEN age_years BETWEEN 19 AND 30 THEN '19-30'
    WHEN age_years BETWEEN 31 AND 45 THEN '31-45'
    WHEN age_years BETWEEN 46 AND 55 THEN '46-55'
    WHEN age_years BETWEEN 56 AND 65 THEN '56-65'
    WHEN age_years BETWEEN 66 AND 75 THEN '66-75'
    WHEN age_years BETWEEN 76 AND 85 THEN '76-85'
    ELSE '>85'
  END AS age_range,
  COUNT(*)::bigint AS user_count
FROM (
  SELECT
    p.user_id,
    FLOOR(EXTRACT(YEAR FROM AGE(COALESCE(p_ref_date, CURRENT_DATE), p.birth_date)))::int AS age_years
  FROM public.person p
) t
GROUP BY
  CASE
    WHEN age_years BETWEEN 0 AND 18 THEN '0-18'
    WHEN age_years BETWEEN 19 AND 30 THEN '19-30'
    WHEN age_years BETWEEN 31 AND 45 THEN '31-45'
    WHEN age_years BETWEEN 46 AND 55 THEN '46-55'
    WHEN age_years BETWEEN 56 AND 65 THEN '56-65'
    WHEN age_years BETWEEN 66 AND 75 THEN '66-75'
    WHEN age_years BETWEEN 76 AND 85 THEN '76-85'
    ELSE '>85'
  END
ORDER BY MIN(age_years);
$$;

/*
 * The function stats_affiliated_by_type will return the total number of
 * affiliated businesses grouped by their business type.
 */

CREATE OR REPLACE FUNCTION public.stats_affiliated_by_type()
RETURNS TABLE (
  business_type character varying,
  total bigint
)
LANGUAGE sql
AS $$
SELECT
  bt.name AS business_type,
  COUNT(ab.affiliated_business_id)::bigint AS total
FROM public.affiliatedbusiness ab
LEFT JOIN public.businesstype bt ON ab.business_type_id = bt.business_type_id
GROUP BY bt.name
ORDER BY total DESC;
$$;

/*
 * The function stats_products_redeemed_by_month will return the total number of
 * products redeemed grouped by month within an optional date range.
 */

CREATE OR REPLACE FUNCTION public.stats_products_redeemed_by_month(
  p_year integer DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::int
)
RETURNS TABLE (
  year integer,
  month integer,
  month_name text,
  total_products numeric
)
LANGUAGE sql
AS $$
SELECT
  EXTRACT(YEAR FROM ab.created_at)::int AS year,
  EXTRACT(MONTH FROM ab.created_at)::int AS month,
  TO_CHAR(ab.created_at, 'FMMonth') AS month_name,
  COALESCE(SUM(ab.product_amount), 0) AS total_products
FROM public.affiliatedbusinesstransaction ab
WHERE EXTRACT(YEAR FROM ab.created_at)::int = p_year
GROUP BY year, month, month_name
ORDER BY month DESC;
$$;

/*
 * The function stats_products_redeemed_by_year will return the total number of
 * products redeemed grouped by year within an optional date range.
 */

CREATE OR REPLACE FUNCTION public.stats_products_redeemed_by_year()
RETURNS TABLE (
  year integer,
  total_products numeric
)
LANGUAGE sql
AS $$
SELECT
  EXTRACT(YEAR FROM ab.created_at)::int AS year,
  COALESCE(SUM(ab.product_amount), 0) AS total_products
FROM public.affiliatedbusinesstransaction ab
GROUP BY year
ORDER BY year DESC;
$$;

