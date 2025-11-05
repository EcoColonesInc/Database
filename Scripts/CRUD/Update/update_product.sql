CREATE OR REPLACE FUNCTION public.update_product(
    p_product_id uuid,
    p_product_name character varying DEFAULT NULL,
    p_description character varying DEFAULT NULL,
    p_state public."state" DEFAULT NULL
)
RETURNS public.product
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.product;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.product AS t
    SET
        product_name = COALESCE(p_product_name, t.product_name),
        description = COALESCE(p_description, t.description),
        state = COALESCE(p_state, t.state),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.product_id = p_product_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'product % not found', p_product_id;
    END IF;

    RETURN v_row;
END;
$function$;