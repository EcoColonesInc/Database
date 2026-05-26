CREATE OR REPLACE FUNCTION public.update_userrecycling(
    p_user_recycling uuid,
    p_person_id uuid DEFAULT NULL,
    p_collection_center_id uuid DEFAULT NULL,
    p_amount_recycle numeric DEFAULT NULL
)
RETURNS public.userrecycling
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.userrecycling;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.userrecycling AS t
    SET
        person_id = COALESCE(p_person_id, t.person_id),
        collection_center_id = COALESCE(p_collection_center_id, t.collection_center_id),
        amount_recycle = COALESCE(p_amount_recycle, t.amount_recycle),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.user_recycling = p_user_recycling
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'userrecycling % not found', p_user_recycling;
    END IF;

    RETURN v_row;
END;
$function$;