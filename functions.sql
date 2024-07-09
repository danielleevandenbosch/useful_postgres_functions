CREATE OR REPLACE FUNCTION AAND(BOOLEAN, BOOLEAN, VARIADIC BOOLEAN[])
RETURNS BOOLEAN AS $$
BEGIN
    FOR i IN array_lower($3, 1)..array_upper($3, 1) LOOP
        IF NOT $3[i] THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    
    RETURN $1 AND $2;
END;
$$ LANGUAGE plpgsql;
