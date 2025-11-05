CREATE OR REPLACE FUNCTION public.update_unit(
    p_unit_id uuid,
    p_unit_name character varying DEFAULT NULL,
    p_unit_exchange integer DEFAULT NULL
)
RETURNS public.unit
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.unit;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.unit AS t
    SET
        unit_name = COALESCE(p_unit_name, t.unit_name),
        unit_exchange = COALESCE(p_unit_exchange, t.unit_exchange),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.unit_id = p_unit_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'unit % not found', p_unit_id;
    END IF;

    RETURN v_row;
END;
$function$;