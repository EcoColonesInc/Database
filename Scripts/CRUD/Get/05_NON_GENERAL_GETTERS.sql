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
    
    -- Cantidad total vendida por todos los ítems
    SUM(abi.product_amount)::numeric AS total_quantity_sold,

    -- Cantidad de veces que fue comprado (transacciones donde aparece)
    COUNT(*) AS times_purchased

  FROM public.affiliatedbusinesstransactionitem abi
  JOIN public.product p
    ON p.product_id = abi.product_id
  JOIN public.affiliatedbusinessxproduct abxp
    ON abxp.product_id = p.product_id
  JOIN public.affiliatedbusiness b
    ON b.affiliated_business_id = abxp.affiliated_business_id
  JOIN public.affiliatedbusinesstransaction abt
    ON abt.ab_transaction_id = abi.ab_transaction_id

  GROUP BY 
    p.product_name,
    abxp.product_price,
    b.affiliated_business_name

  ORDER BY 
    SUM(abi.product_amount) DESC;  -- más vendidos primero
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
  product_names text,
  total_price integer,
  total_product_amount numeric,
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

    -- Combinar productos en una lista
    string_agg(prod.product_name, ', ' ORDER BY prod.product_name) AS product_names,

    -- total de la transacción viene de la cabecera
    MAX(abt.total_price) AS total_price,

    -- sumar total de productos del carrito
    SUM(abi.product_amount)::numeric AS total_product_amount,

    abt.transaction_code,
    MAX(abt.state) AS state,
    MAX(abt.created_at) AS created_at

  FROM public.affiliatedbusinesstransaction abt
  JOIN public.affiliatedbusinesstransactionitem abi
      ON abi.ab_transaction_id = abt.ab_transaction_id
  JOIN public.product prod
      ON prod.product_id = abi.product_id
  JOIN public.affiliatedbusiness ab
      ON ab.affiliated_business_id = abt.affiliated_business_id
  LEFT JOIN public.person per
      ON per.user_id = abt.person_id
  LEFT JOIN public.currency cur
      ON cur.currency_id = abt.currency_id

  WHERE abt.affiliated_business_id = p_affiliated_business_id
    AND (p_user_name IS NULL OR per.user_name ILIKE ('%' || p_user_name || '%'))
    AND (p_date IS NULL OR date(abt.created_at) = p_date)
    AND (p_product_name IS NULL OR prod.product_name ILIKE ('%' || p_product_name || '%'))
    AND (p_total_price IS NULL OR abt.total_price = p_total_price)

  GROUP BY
    per.user_name,
    per.first_name,
    per.last_name,
    ab.affiliated_business_name,
    cur.currency_name,
    cur.currency_exchange,
    abt.transaction_code

  ORDER BY MAX(abt.created_at) DESC;
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
    SELECT cc.person_id,
           COALESCE(SUM(cc.total_points), 0)::bigint AS acum
    FROM public.collectioncentertransaction cc
    WHERE (p_start_date IS NULL OR cc.created_at >= p_start_date)
      AND (p_end_date IS NULL OR cc.created_at <= p_end_date)
    GROUP BY cc.person_id
  ), s AS (
    SELECT ab.person_id,
           COALESCE(SUM(ab.total_price)::bigint, 0) AS spent
    FROM public.affiliatedbusinesstransaction ab
    JOIN public.parameter pa
      ON pa.name = 'default_currency'
     AND ab.currency_id = pa.value
    WHERE (p_start_date IS NULL OR ab.created_at >= p_start_date)
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
  SELECT *
  FROM per
  ORDER BY acumulated_points DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
 * Function to get the most recycled materials grouped by collection center.
 * Returns collection_center_name, material_name and total amount (or weight).
 * Supports optional filters: collection_center_id, start/end timestamps and limit.
 */

CREATE OR REPLACE FUNCTION public.get_most_recycled_materials()
RETURNS TABLE (
  collection_center_name character varying,
  material_name character varying,
  total_amount numeric
)
AS $$
  SELECT
    cc.name,
    m.name,
    SUM(ci.material_amount)::numeric AS total_amount
  FROM public.collectioncentertransaction t
  JOIN public.collectioncentertransactionitem ci
    ON ci.cc_transaction_id = t.cc_transaction_id
  JOIN public.collectioncenter cc
    ON cc.collectioncenter_id = t.collection_center_id
  JOIN public.material m
    ON m.material_id = ci.material_id
  GROUP BY cc.name, m.name
  ORDER BY SUM(ci.material_amount) DESC
  LIMIT 5; -- Top 5 overall
$$ LANGUAGE sql SECURITY DEFINER;
