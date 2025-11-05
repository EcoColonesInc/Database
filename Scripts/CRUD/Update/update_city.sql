
CREATE OR REPLACE FUNCTION public.update_city(
    p_city_id uuid,
    p_province_id uuid DEFAULT NULL,
    p_city_name character varying DEFAULT NULL,
    p_updated_by uuid
)
RETURNS public.city
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.city;
BEGIN
    UPDATE public.city AS t
    SET
        province_id = COALESCE(p_province_id, t.province_id),
        city_name = COALESCE(p_city_name, t.city_name),
        updated_by = p_updated_by,
        updated_at = NOW()
    WHERE t.city_id = p_city_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'city % not found', p_city_id;
    END IF;

    RETURN v_row;
END;
$function$;
