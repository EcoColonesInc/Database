-- Binnacle Getter

CREATE OR REPLACE FUNCTION public.get_binnacle(
  p_user_name character varying DEFAULT NULL,
  p_start_date date DEFAULT NULL,
  p_end_date date DEFAULT NULL,
  p_start_time time DEFAULT NULL,
  p_end_time time DEFAULT NULL,
  p_change_type character varying DEFAULT NULL
)
RETURNS TABLE (
  binnacle_id uuid,
  object_name character varying,
  change_type character varying,
  old_value text,
  new_value text,
  user_id uuid,
  full_name text,
  user_name character varying,
  date timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.binnacle_id,
    b.object_name,
    b.change_type,
    b.old_value,
    b.new_value,
    b.user_id,
    CONCAT(p.first_name, ' ', p.last_name, ' ', COALESCE(p.second_last_name, '')) AS full_name,
    p.user_name,
    b.date
  FROM public.binnacle AS b
  LEFT JOIN public.person AS p
    ON b.user_id = p.user_id
  WHERE (
    p_user_name IS NULL
    OR (
      (p.first_name IS NOT NULL OR p.last_name IS NOT NULL OR p.second_last_name IS NOT NULL)
      AND CONCAT(p.first_name, ' ', p.last_name, ' ', COALESCE(p.second_last_name, '')) ILIKE '%' || p_user_name || '%'
    )
    OR (p.user_name IS NOT NULL AND p.user_name ILIKE '%' || p_user_name || '%')
  )
  AND (p_start_date IS NULL OR b.date::date >= p_start_date)
  AND (p_end_date IS NULL OR b.date::date <= p_end_date)
  AND (p_start_time IS NULL OR b.date::time >= p_start_time)
  AND (p_end_time IS NULL OR b.date::time <= p_end_time)
  AND (p_change_type IS NULL OR b.change_type ILIKE '%' || p_change_type || '%')
  ORDER BY b.date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Collection Center X Material Getter

CREATE OR REPLACE FUNCTION public.get_collectioncenterxmaterial()
RETURNS TABLE (
  collection_center_x_product_id uuid,
  material_name character varying,
  collection_center_name character varying,
  unit_name character varying,
  unit_exchange integer,
  full_name text,
  updated_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cxm.collection_center_x_product_id,
    m.name AS material_name,
    cc.name AS collection_center_name,
    u.unit_name,
    u.unit_exchange,
    CONCAT(p.first_name, ' ', p.last_name, ' ', COALESCE(p.second_last_name, '')) AS full_name,
    cxm.updated_at
  FROM public.collectioncenterxmaterial AS cxm
  JOIN public.material AS m
    ON cxm.material_id = m.material_id
  JOIN public.unit AS u
    ON m.unit_id = u.unit_id
  JOIN public.collectioncenter AS cc
    ON cxm.collection_center_id = cc.collectioncenter_id
  LEFT JOIN public.person AS p
    ON cxm.updated_by = p.user_id
  ORDER BY cxm.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Materials from Collection Center by unit_id

CREATE OR REPLACE FUNCTION public.get_collectioncenterxmaterial(p_collection_center_id uuid)
RETURNS TABLE (
  collection_center_x_product_id uuid,
  material_name character varying,
  collection_center_name character varying,
  unit_name character varying,
  unit_exchange integer,
  full_name text,
  updated_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cxm.collection_center_x_product_id,
    m.name AS material_name,
    cc.name AS collection_center_name,
    u.unit_name,
    u.unit_exchange,
    CONCAT(p.first_name, ' ', p.last_name, ' ', COALESCE(p.second_last_name, '')) AS full_name,
    cxm.updated_at
  FROM public.collectioncenterxmaterial AS cxm
  JOIN public.material AS m
    ON cxm.material_id = m.material_id
  JOIN public.unit AS u
    ON m.unit_id = u.unit_id
  JOIN public.collectioncenter AS cc
    ON cxm.collection_center_id = cc.collectioncenter_id
  LEFT JOIN public.person AS p
    ON cxm.updated_by = p.user_id
  WHERE cxm.collection_center_id = p_collection_center_id
  ORDER BY cxm.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Getter for Parameter (Default_Currency)



-- *********************************************************************

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
  material_recycled numeric,
  role public.role
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
    COALESCE(SUM(cct.material_amount), 0) AS material_recycled,
    p.role
  FROM public.person AS p
  JOIN auth.users AS u
    ON u.id = p.user_id
  LEFT JOIN public.point AS po
    ON po.person_id = p.user_id
  LEFT JOIN public.collectioncentertransaction cct
    ON cct.person_id = p.user_id
  WHERE p.user_id = p_user_id
  GROUP BY p.first_name, p.last_name, p.second_last_name, p.user_name, u.email, p.document_type, p.identification, p.gender, p.telephone_number, p.birth_date, po.point_amount, p.role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
 * Store procedure to gets user's transaction history in Affiliated Business.
 * It will be used in "Transacciones Usuario y Dashboard Usuario".
 */ 

CREATE OR REPLACE FUNCTION public.get_user_affiliated_transactions(
  p_user_id uuid,
  p_date date DEFAULT NULL
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
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.user_name,
    p.first_name,
    p.last_name,
    ab.affiliated_business_name,
    c.currency_name,
    c.currency_exchange,
    pr.product_name,
    abt.total_price,
    abt.product_amount,
    abt.transaction_code,
    abt.state,
    abt.created_at
  FROM public.affiliatedbusinesstransaction abt
  JOIN public.person p
    ON p.user_id = abt.person_id
  JOIN public.affiliatedbusiness ab
    ON ab.affiliated_business_id = abt.affiliated_business_id
  JOIN public.currency c
    ON c.currency_id = abt.currency_id
  JOIN public.product pr
    ON pr.product_id = abt.product_id
  WHERE abt.person_id = p_user_id
    AND (p_date IS NULL OR abt.created_at::date = p_date)
  ORDER BY abt.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
 * Store procedure to gets user's transaction history in Collection Centers.
 * It will be used in "Transacciones Usuario y Dashboard Usuario".
 */ 

CREATE OR REPLACE FUNCTION public.get_user_collectioncenter_transactions(
  p_user_id uuid,
  p_date date DEFAULT NULL
)
RETURNS TABLE (
  user_name character varying,
  first_name character varying,
  last_name character varying,
  collection_center_name character varying,
  material_name character varying,
  total_points integer,
  material_amount numeric,
  created_at timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.user_name,
    p.first_name,
    p.last_name,
    cc.name AS collection_center_name,
    m.name AS material_name,
    cct.total_points,
    cct.material_amount,
    cct.created_at
  FROM public.collectioncentertransaction cct
  LEFT JOIN public.person p
    ON p.user_id = cct.person_id
  JOIN public.collectioncenter cc
    ON cc.collectioncenter_id = cct.collection_center_id
  JOIN public.material m
    ON m.material_id = cct.material_id
  WHERE cct.person_id = p_user_id
    AND (p_date IS NULL OR cct.created_at::date = p_date)
  ORDER BY cct.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

  -- Getter for Default Currency parameter

  CREATE OR REPLACE FUNCTION public.get_default_currency()
  RETURNS TABLE (
    value bigint,
    name character varying
  ) AS $$
  BEGIN
    RETURN QUERY
    SELECT
      c.currency_name,
      c.currency_exchange
    FROM public.currency AS c
    JOIN public.parameter AS p
     ON c.currency_id = p.value
    WHERE p.name = 'default_currency'
    LIMIT 1;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;



