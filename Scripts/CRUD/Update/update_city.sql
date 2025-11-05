CREATE OR REPLACE FUNCTION public.update_city(
    p_city_id uuid,
    p_province_id uuid DEFAULT NULL,
    p_city_name character varying DEFAULT NULL
)
RETURNS public.city
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.city;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.city AS t
    SET
        province_id = COALESCE(p_province_id, t.province_id),
        city_name = COALESCE(p_city_name, t.city_name),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.city_id = p_city_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'city % not found', p_city_id;
    END IF;

    RETURN v_row;
END;
$function$;
