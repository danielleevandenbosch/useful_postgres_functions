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

CREATE OR REPLACE FUNCTION AAND(BOOLEAN, BOOLEAN)
RETURNS BOOLEAN AS $$
/*
    Author: Daniel Van Den Bosch
    Date: 2024-07-10
    Telos: The purpose of this function is to add backward compatibility for ms-excel.
*/
BEGIN
    RETURN $1 AND $2;
END;
$$ LANGUAGE plpgsql;
