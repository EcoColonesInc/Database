/*
 * Store procedure to get the most popular products.
 * It will be used in "Afiliados Home Page / Landing".
 */

CREATE OR REPLACE FUNCTION public.get_most_popular_products()
RETURNS TABLE (
  product_name character varying,
  product_price integer,
  affiliated_business_name character varying,
  total_quantity_sold numeric,
  times_purchased bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.product_name,
    abxp.product_price,
    b.affiliated_business_name,
    COALESCE(SUM(abt.product_amount), 0) AS total_quantity_sold,
    COUNT(*) AS times_purchased
  FROM public.product AS p
  JOIN affiliatedbusinessxproduct AS abxp
    ON abxp.product_id = p.product_id
  JOIN affiliatedbusiness AS b
    ON abxp.affiliated_business_id = b.affiliated_business_id
  JOIN public.affiliatedbusinesstransaction abt
    ON abt.product_id = p.product_id
  GROUP BY p.product_name, abxp.product_price, b.affiliated_business_name
  ORDER BY SUM(abt.product_amount) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
 * Store procedure that gets the affiliated business transactions by affiliated business ID.
 * It also filters the resultas by user_name, date, product and cost.
 * It will be used in "Todas las transacciones en Comercio Afiliado".
 */

CREATE OR REPLACE FUNCTION public.get_affiliated_business_transactions(
  p_affiliated_business_id uuid,
  p_user_name text DEFAULT NULL,
  p_date date DEFAULT NULL,
  p_product_name text DEFAULT NULL,
  p_total_price integer DEFAULT NULL
)
RETURNS TABLE (
  user_name character varying,
  first_name character varying,
  last_name character varying,
  affiliated_business_name character varying,
  currency_name character varying,
  currency_exchange bigint,
  product_name character varying,
  total_price integer,
  product_amount numeric,
  transaction_code character varying,
  state public.state,
  created_at timestamp with time zone
)
AS $$
BEGIN
  RETURN QUERY
  SELECT
    per.user_name,
    per.first_name,
    per.last_name,
    ab.affiliated_business_name,
    cur.currency_name,
    cur.currency_exchange,
    prod.product_name,
    abt.total_price,
    abt.product_amount,
    abt.transaction_code,
    abt.state,
    abt.created_at
  FROM public.affiliatedbusinesstransaction abt
  LEFT JOIN public.person per ON abt.person_id = per.user_id
  LEFT JOIN public.affiliatedbusiness ab ON abt.affiliated_business_id = ab.affiliated_business_id
  LEFT JOIN public.currency cur ON abt.currency_id = cur.currency_id
  LEFT JOIN public.product prod ON abt.product_id = prod.product_id
  WHERE abt.affiliated_business_id = p_affiliated_business_id
    AND (p_user_name IS NULL OR per.user_name ILIKE ('%' || p_user_name || '%'))
    AND (p_date IS NULL OR date(abt.created_at) = p_date)
    AND (p_product_name IS NULL OR prod.product_name ILIKE ('%' || p_product_name || '%'))
    AND (p_total_price IS NULL OR abt.total_price = p_total_price)
  ORDER BY abt.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
 * Function that returns a summary of points accumulated and spent by users 
 * within an optional date range.
  * It will be used in "Consultas de Usuario/Reporte de puntos por Usuario" and "Estadisticas".
 */

CREATE OR REPLACE FUNCTION public.get_points_summary(
  p_start_date timestamptz DEFAULT NULL,
  p_end_date timestamptz DEFAULT NULL
)
RETURNS TABLE (
  first_name character varying,
  last_name character varying,
  acumulated_points bigint,
  spent_points bigint,
  difference bigint,
  total_points bigint
)
AS $$
BEGIN
  RETURN QUERY
  WITH c AS (
    SELECT cc.person_id, COALESCE(SUM(cc.total_points), 0)::bigint AS acum
    FROM public.collectioncentertransaction cc
    WHERE cc.person_id IS NOT NULL
      AND (p_start_date IS NULL OR cc.created_at >= p_start_date)
      AND (p_end_date IS NULL OR cc.created_at <= p_end_date)
    GROUP BY cc.person_id
  ), s AS (
    SELECT ab.person_id,
          COALESCE(SUM(ab.total_price)::bigint, 0) AS spent
    FROM public.affiliatedbusinesstransaction ab
    JOIN public.parameter pa
        ON pa.name = 'default_currency'
        AND ab.currency_id = pa.value
    WHERE ab.person_id IS NOT NULL
      AND (p_start_date IS NULL OR ab.created_at >= p_start_date)
      AND (p_end_date IS NULL OR ab.created_at <= p_end_date)
    GROUP BY ab.person_id
  ), users AS (
    SELECT COALESCE(c.person_id, s.person_id) AS person_id,
           COALESCE(c.acum, 0) AS acumulated_points,
           COALESCE(s.spent, 0) AS spent_points
    FROM c
    FULL JOIN s ON c.person_id = s.person_id
  ), per AS (
    SELECT p.first_name,
           p.last_name,
           u.acumulated_points,
           u.spent_points,
           (u.acumulated_points - u.spent_points) AS difference,
           (u.acumulated_points + u.spent_points) AS total_points
    FROM users u
    LEFT JOIN public.person p ON p.user_id = u.person_id
  )
  SELECT
    per.first_name,
    per.last_name,
    per.acumulated_points,
    per.spent_points,
    per.difference,
    per.total_points
  FROM per
  ORDER BY per.acumulated_points NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
