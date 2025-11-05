CREATE OR REPLACE FUNCTION public.update_affiliatedbusinessxproduct(
    p_affiliated_business_x_prod uuid,
    p_product_id uuid DEFAULT NULL,
    p_affiliated_business_id uuid DEFAULT NULL,
    p_product_price integer DEFAULT NULL
)
RETURNS public.affiliatedbusinessxproduct
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.affiliatedbusinessxproduct;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.affiliatedbusinessxproduct AS t
    SET
        product_id = COALESCE(p_product_id, t.product_id),
        affiliated_business_id = COALESCE(p_affiliated_business_id, t.affiliated_business_id),
        product_price = COALESCE(p_product_price, t.product_price),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.affiliated_business_x_prod = p_affiliated_business_x_prod
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'affiliatedbusinessxproduct % not found', p_affiliated_business_x_prod;
    END IF;

    RETURN v_row;
END;
$function$;