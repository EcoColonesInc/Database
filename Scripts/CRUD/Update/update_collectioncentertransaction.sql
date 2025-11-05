CREATE OR REPLACE FUNCTION public.update_collectioncentertransaction(
    p_cc_transaction_id uuid,
    p_person_id uuid DEFAULT NULL,
    p_collection_center_id uuid DEFAULT NULL,
    p_material_id uuid DEFAULT NULL,
    p_total_points integer DEFAULT NULL,
    p_material_amount numeric DEFAULT NULL
)
RETURNS public.collectioncentertransaction
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.collectioncentertransaction;
    user_uuid uuid;
BEGIN
    -- Obtener el usuario autenticado
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.collectioncentertransaction AS t
    SET
        person_id = COALESCE(p_person_id, t.person_id),
        collection_center_id = COALESCE(p_collection_center_id, t.collection_center_id),
        material_id = COALESCE(p_material_id, t.material_id),
        total_points = COALESCE(p_total_points, t.total_points),
        material_amount = COALESCE(p_material_amount, t.material_amount),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.cc_transaction_id = p_cc_transaction_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'collectioncentertransaction % not found', p_cc_transaction_id;
    END IF;
    RETURN v_row;
END;
$function$;
