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




