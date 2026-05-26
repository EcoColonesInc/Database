CREATE OR REPLACE FUNCTION public.update_parameter(
    p_parameter_id uuid,
    p_name character varying DEFAULT NULL,
    p_value uuid DEFAULT NULL
)
RETURNS public.parameter
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.parameter;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.parameter AS t
    SET
        name = COALESCE(p_name, t.name),
        value = COALESCE(p_value, t.value),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.parameter_id = p_parameter_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'parameter % not found', p_parameter_id;
    END IF;

    RETURN v_row;
END;
$function$;