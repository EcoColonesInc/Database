CREATE OR REPLACE FUNCTION public.update_material(
    p_material_id uuid,
    p_unit_id uuid DEFAULT NULL,
    p_name character varying DEFAULT NULL,
    p_equivalent_points integer DEFAULT NULL
)
RETURNS public.material
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.material;
    user_uuid uuid;
BEGIN
    user_uuid := auth.uid();
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    UPDATE public.material AS t
    SET
        unit_id = COALESCE(p_unit_id, t.unit_id),
        name = COALESCE(p_name, t.name),
        equivalent_points = COALESCE(p_equivalent_points, t.equivalent_points),
        updated_by = user_uuid,
        updated_at = NOW()
    WHERE t.material_id = p_material_id
    RETURNING t.* INTO v_row;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'material % not found', p_material_id;
    END IF;

    RETURN v_row;
END;
$function$;