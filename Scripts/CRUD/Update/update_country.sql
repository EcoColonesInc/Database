CREATE OR REPLACE FUNCTION public.update_country(
    p_country_id uuid,
    p_country_name character varying DEFAULT NULL
)
RETURNS public.country
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.country;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.country AS t
    SET
        country_name = COALESCE(p_country_name, t.country_name),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.country_id = p_country_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'country % not found', p_country_id;
    END IF;
    RETURN v_row;
END;
$function$;
