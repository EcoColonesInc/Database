CREATE OR REPLACE FUNCTION public.update_point(
    p_person_id uuid,
    p_point_amount bigint DEFAULT NULL
)
RETURNS public.point
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.point;
BEGIN
    UPDATE public.point AS t
    SET
        point_amount = COALESCE(p_point_amount, t.point_amount)
    WHERE t.person_id = p_person_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'point % not found', p_person_id;
    END IF;

    RETURN v_row;
END;
$function$;