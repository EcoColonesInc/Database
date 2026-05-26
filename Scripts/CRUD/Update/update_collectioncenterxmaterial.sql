CREATE OR REPLACE FUNCTION public.update_collectioncenterxmaterial(
    p_collection_center_x_product_id uuid,
    p_material_ID uuid DEFAULT NULL,
    p_collection_center_id uuid DEFAULT NULL,
    p_product_id uuid DEFAULT NULL,
    p_stock_quantity integer DEFAULT NULL
)
RETURNS public.collectioncenterxmaterial
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.collectioncenterxmaterial;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.collectioncenterxmaterial AS t
    SET
        material_id = COALESCE(p_material_ID, t.material_id),
        collection_center_id = COALESCE(p_collection_center_id, t.collection_center_id),
        product_id = COALESCE(p_product_id, t.product_id),
        stock_quantity = COALESCE(p_stock_quantity, t.stock_quantity),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.collection_center_x_product_id = p_collection_center_x_product_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'collectioncenterxmaterial % not found', p_collection_center_x_product_id;
    END IF;
    RETURN v_row;
END;
$function$;
