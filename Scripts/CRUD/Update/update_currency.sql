CREATE OR REPLACE FUNCTION public.update_currency(
    p_currency_id uuid,
    p_currency_name character varying DEFAULT NULL,
    p_currency_exchange bigint DEFAULT NULL
)
RETURNS public.currency
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.currency;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.currency AS t
    SET
        currency_name = COALESCE(p_currency_name, t.currency_name),
        currency_exchange = COALESCE(p_currency_exchange, t.currency_exchange),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.currency_id = p_currency_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'currency % not found', p_currency_id;
    END IF;

    RETURN v_row;
END;
$function$;