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
 * Store procedure to get the user's profile information.
 * It will be used in "Perfil de Usuario".
 */

CREATE OR REPLACE FUNCTION public.get_profile_info(p_user_id uuid)
RETURNS TABLE (
  first_name character varying,
  last_name character varying,
  second_last_name character varying,
  user_name character varying,
  email character varying,
  document_type public.document_type,
  identification character varying,
  gender public.gender,
  telephone_number character varying,
  birth_date date,
  acumulated_points bigint,
  material_recycled numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.first_name,
    p.last_name,
    p.second_last_name,
    p.user_name,
    u.email,
    p.document_type,
    p.identification,
    p.gender,
    p.telephone_number,
    p.birth_date,
    COALESCE(po.point_amount, 0) AS acumulated_points,
    COALESCE(SUM(cct.material_amount), 0) AS material_recycled
  FROM public.person AS p
  JOIN auth.users AS u
    ON u.id = p.user_id
  LEFT JOIN public.point AS po
    ON po.person_id = p.user_id
  LEFT JOIN public.collectioncentertransaction cct
    ON cct.person_id = p.user_id
  WHERE p.user_id = p_user_id
  GROUP BY p.first_name, p.last_name, p.second_last_name, p.user_name, u.email, p.document_type, p.identification, p.gender, p.telephone_number, p.birth_date, po.point_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;




