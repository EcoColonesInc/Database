CREATE OR REPLACE FUNCTION public.update_district(
    p_district_id uuid,
    p_city_id uuid DEFAULT NULL,
    p_district_name character varying DEFAULT NULL
)
RETURNS public.district
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.district;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.district AS t
    SET
        city_id = COALESCE(p_city_id, t.city_id),
        district_name = COALESCE(p_district_name, t.district_name),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.district_id = p_district_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'district % not found', p_district_id;
    END IF;

    RETURN v_row;
END;
$function$;