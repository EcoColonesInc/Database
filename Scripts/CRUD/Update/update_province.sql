CREATE OR REPLACE FUNCTION public.update_province(
    p_province_id uuid,
    p_country_id uuid DEFAULT NULL,
    p_province_name character varying DEFAULT NULL
)
RETURNS public.province
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.province;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.province AS t
    SET
        country_id = COALESCE(p_country_id, t.country_id),
        province_name = COALESCE(p_province_name, t.province_name),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.province_id = p_province_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'province % not found', p_province_id;
    END IF;

    RETURN v_row;
END;
$function$;