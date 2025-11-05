CREATE OR REPLACE FUNCTION public.update_person(
    p_user_id uuid,
    p_first_name character varying DEFAULT NULL,
    p_last_name character varying DEFAULT NULL,
    p_second_last_name character varying DEFAULT NULL,
    p_telephone_number character varying DEFAULT NULL,
    p_birth_date date DEFAULT NULL,
    p_user_name character varying DEFAULT NULL,
    p_identification numeric DEFAULT NULL,
    p_role public."Role" DEFAULT NULL,
    p_gender public."Gender" DEFAULT NULL,
    p_document_type public."DocumentType" DEFAULT NULL
)
RETURNS public.person
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.person;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.person AS t
    SET
        first_name = COALESCE(p_first_name, t.first_name),
        last_name = COALESCE(p_last_name, t.last_name),
        second_last_name = COALESCE(p_second_last_name, t.second_last_name),
        telephone_number = COALESCE(p_telephone_number, t.telephone_number),
        birth_date = COALESCE(p_birth_date, t.birth_date),
        user_name = COALESCE(p_user_name, t.user_name),
        identification = COALESCE(p_identification, t.identification),
        role = COALESCE(p_role, t.role),
        gender = COALESCE(p_gender, t.gender),
        document_type = COALESCE(p_document_type, t.document_type),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.user_id = p_user_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'person % not found', p_user_id;
    END IF;

    RETURN v_row;
END;
$function$;