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


CREATE OR REPLACE FUNCTION public.iindex_int(
    arr integer[],
    row_num integer,
    col_num integer DEFAULT 1
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    result integer;
BEGIN
    /*
        Author:  Daniel L. Van Den Bosch
        Date:    2024-12-02
     */
    IF col_num IS NULL THEN
        -- Handle one-dimensional array
        IF row_num IS NULL THEN
            RAISE EXCEPTION 'row_num cannot be NULL for one-dimensional arrays';
        END IF;
        result := arr[row_num];
    ELSE
        -- Handle two-dimensional array
        IF row_num IS NULL OR col_num IS NULL THEN
            RAISE EXCEPTION 'row_num and col_num cannot be NULL for two-dimensional arrays';
        END IF;
        result := arr[row_num][col_num];
    END IF;
    RETURN result;
EXCEPTION
    WHEN array_subscript_error THEN
        RAISE EXCEPTION 'Index out of bounds: row % col %', row_num, col_num;
END;
$$;




CREATE OR REPLACE FUNCTION public.llarge_int(
    arr integer[],
    k integer
)
RETURNS integer
LANGUAGE sql
AS $$
    /*
        Author:  Daniel L. Van Den Bosch
        Date:    2024-12-02
     */
    SELECT val
    FROM (
        SELECT val, ROW_NUMBER() OVER (ORDER BY val DESC) as rn
        FROM unnest(arr) as val
    ) sub
    WHERE rn = k;
$$;
