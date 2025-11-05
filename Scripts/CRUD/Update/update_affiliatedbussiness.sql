CREATE OR REPLACE FUNCTION public.update_affiliatedbussiness(
    p_affiliated_business_id uuid,
    p_district_id uuid DEFAULT NULL,
    p_business_type_id uuid DEFAULT NULL,
    p_affiliated_business_name character varying DEFAULT NULL,
    p_phone character varying DEFAULT NULL,
    p_manager_name character varying DEFAULT NULL,
    p_email character varying DEFAULT NULL,
    p_description character varying DEFAULT NULL,
    p_updated_by uuid
)
RETURNS public.affiliatedbussiness
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.affiliatedbussiness;
BEGIN
    UPDATE public.affiliatedbussiness AS t
    SET
        district_id = COALESCE(p_district_id, t.district_id),
        business_type_id = COALESCE(p_business_type_id, t.business_type_id),
        affiliated_business_name = COALESCE(p_affiliated_business_name, t.affiliated_business_name),
        phone = COALESCE(p_phone, t.phone),
        manager_name = COALESCE(p_manager_name, t.manager_name),
        email = COALESCE(p_email, t.email),
        description = COALESCE(p_description, t.description),
        updated_by = p_updated_by,
        updated_at = NOW()
    WHERE t.affiliated_business_id = p_affiliated_business_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'affiliatedbussiness % not found', p_affiliated_business_id;
    END IF;

    RETURN v_row;
END;
$function$;
