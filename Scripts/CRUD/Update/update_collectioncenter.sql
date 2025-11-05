CREATE OR REPLACE FUNCTION public.update_collectioncenter(
    p_collectioncenter_id uuid,
    p_person_id uuid DEFAULT NULL,
    p_district_id uuid DEFAULT NULL,
    p_name character varying DEFAULT NULL,
    p_phone character varying DEFAULT NULL,
    p_manager_name character varying DEFAULT NULL,
    p_latitude numeric DEFAULT NULL,
    p_longitude numeric DEFAULT NULL
)
RETURNS public.collectioncenter
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.collectioncenter;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.collectioncenter AS t
    SET 
        person_id = COALESCE(p_person_id, t.person_id),
        district_id = COALESCE(p_district_id, t.district_id),
        name = COALESCE(p_name, t.name),
        phone = COALESCE(p_phone, t.phone),
        manager_name = COALESCE(p_manager_name, t.manager_name),
        latitude = COALESCE(p_latitude, t.latitude),
        longitude = COALESCE(p_longitude, t.longitude),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.collectioncenter_id = p_collectioncenter_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'collectioncenter % not found', p_collectioncenter_id;
    END IF;
    RETURN v_row;
END;
$function$;
