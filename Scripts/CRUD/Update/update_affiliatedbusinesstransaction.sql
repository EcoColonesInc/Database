CREATE OR REPLACE FUNCTION public.update_affiliatedbusinesstransaction(
    p_ab_transaction_id uuid,               
    p_person_id uuid DEFAULT NULL,          
    p_affiliated_business_id uuid DEFAULT NULL,
    p_currency_id uuid DEFAULT NULL,        
    p_product_id uuid DEFAULT NULL,         
    p_total_price integer DEFAULT NULL,    
    p_product_amount numeric(10, 2) DEFAULT NULL, 
    p_transaction_code varchar(100) DEFAULT NULL, 
    p_updated_by uuid DEFAULT NULL,                      
    p_state public."state" DEFAULT NULL       
)
RETURNS public.affiliatedbusinesstransaction    
LANGUAGE plpgsql
AS $function$
DECLARE
    v_row public.affiliatedbusinesstransaction;  -- Variable para capturar la fila actualizada
BEGIN
    -- Validación: updated_by es requerido lógicamente
    IF p_updated_by IS NULL THEN
        RAISE EXCEPTION 'updated_by no puede ser NULL';
    END IF;

    -- Actualiza solo los campos provistos (no nulos). Los NULL conservan el valor actual mediante COALESCE.
    UPDATE public.affiliatedbusinesstransaction AS t
    SET
        person_id = COALESCE(p_person_id, t.person_id),                              -- Mantiene si es NULL
        affiliated_business_id = COALESCE(p_affiliated_business_id, t.affiliated_business_id),
        currency_id = COALESCE(p_currency_id, t.currency_id),
        product_id = COALESCE(p_product_id, t.product_id),
        total_price = COALESCE(p_total_price, t.total_price),
        product_amount = COALESCE(p_product_amount, t.product_amount),
        transaction_code = COALESCE(p_transaction_code, t.transaction_code),
        updated_by = p_updated_by,                                                   -- Siempre se actualiza
        updated_at = NOW(),                                                          -- Timestamp de auditoría
        state = COALESCE(p_state, t.state)
    WHERE t.ab_transaction_id = p_ab_transaction_id                                  -- Filtro por PK
    RETURNING t.* INTO v_row;                                                        -- Devuelve la fila actualizada

    -- Si no se encontró la fila, lanza una excepción explícita.
    IF NOT FOUND THEN
        RAISE EXCEPTION 'affiliatedbusinesstransaction % not found', p_ab_transaction_id;
    END IF;

    RETURN v_row;
END;
$function$;