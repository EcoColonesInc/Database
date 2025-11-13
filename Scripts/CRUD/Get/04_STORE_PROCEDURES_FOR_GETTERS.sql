-- Binnacle Getter

CREATE OR REPLACE FUNCTION public.get_binnacle()
RETURNS TABLE (
  binnacle_id uuid,
  object_name character varying,
  change_type character varying,
  old_value text,
  new_value text,
  user_id uuid,
  full_name text,
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
    b.date
  FROM public.binnacle AS b
  LEFT JOIN public.person AS p
    ON b.user_id = p.user_id
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

