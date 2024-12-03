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

create or replace function public.oor(VARIADIC conditions boolean[]) returns boolean
    immutable
    language plpgsql
as
$$
/*
    Author: Daniel L. Van Den Bosch
    Date: 2024-12-02
 */
BEGIN
    
    -- If any condition is true, return true
    IF EXISTS (
        SELECT 1
        FROM unnest(conditions) AS cond
        WHERE cond IS TRUE
    ) THEN
        RETURN TRUE;
    END IF;

    -- If no conditions are true, return false
    RETURN FALSE;
END;
$$;



create or replace function public.iindex_int(arr integer[], row_num integer, col_num integer DEFAULT 1) returns integer
    language plpgsql
as
$$
DECLARE
    result integer;
    row_num_is_null boolean := FALSE;
    col_num_is_null boolean := FALSE;
BEGIN
    /*
        Author:  Daniel L. Van Den Bosch
        Date:    2024-12-02
     */
    IF row_num IS NULL THEN
        row_num_is_null := TRUE;
    END IF;
    IF col_num IS NULL THEN
        col_num_is_null := TRUE;
    END IF;


    IF col_num_is_null THEN
        -- Handle one-dimensional array
        IF row_num_is_null THEN
            RAISE EXCEPTION 'row_num cannot be NULL for one-dimensional arrays';
        END IF;
        result := arr[row_num];
    ELSE
        -- Handle two-dimensional array
        IF row_num_is_null OR col_num_is_null THEN
            IF row_num_is_null AND col_num_is_null THEN
                --RAISE EXCEPTION 'row_num and col_num cannot be NULL for two-dimensional arrays. They are both NULL';
                RETURN NULL;
            ELSEIF row_num_is_null THEN
                --RAISE EXCEPTION 'row_num cannot be NULL for two-dimensional arrays';
                RETURN NULL;
            ELSEIF col_num_is_null THEN
                --RAISE EXCEPTION 'col_num cannot be NULL for two-dimensional arrays';
                RETURN NULL;
            END IF;
        END IF;
        result := arr[row_num][col_num];
    END IF;
    RETURN result;
EXCEPTION
    WHEN array_subscript_error THEN
        --RAISE EXCEPTION 'Index out of bounds: row % col %', row_num, col_num;
        RETURN NULL;
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





CREATE OR REPLACE FUNCTION public.mmatch_int(
    lookup_value integer,
    lookup_array integer[],
    match_type integer DEFAULT 1
)
RETURNS integer
LANGUAGE plpgsql
AS $$
/*
    Author:  Daniel L. Van Den Bosch
    Date:    2024-12-02
 */
BEGIN
    IF match_type NOT IN (-1, 0, 1) THEN
        RAISE EXCEPTION 'Invalid match_type: %, must be -1, 0, or 1', match_type;
    END IF;

    RETURN (
        WITH indexed_array AS (
            SELECT val, idx
            FROM unnest(lookup_array) WITH ORDINALITY AS t(val, idx)
            WHERE val IS NOT NULL
        ),
        filtered_array AS (
            SELECT val, idx
            FROM indexed_array
            WHERE
                (match_type = 0 AND val = lookup_value) OR
                (match_type = 1 AND val <= lookup_value) OR
                (match_type = -1 AND val >= lookup_value)
        ),
        ordered_array AS (
            SELECT val, idx
            FROM filtered_array
            ORDER BY
                CASE
                    WHEN match_type = 0 THEN NULL
                    WHEN match_type = 1 THEN val * -1
                    WHEN match_type = -1 THEN val * 1
                END,
                idx
        )
        SELECT idx FROM ordered_array LIMIT 1
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.ccountif(
    arr anyarray,
    criteria text
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    count integer := 0;
    operator text;
    operand text;
    sql_query text;
BEGIN
    -- Parse the criteria into operator and operand
    IF criteria ~ '^(<=|>=|<>|=|<|>).*' THEN
        operator := substring(criteria FROM '^(<=|>=|<>|=|<|>)');
        operand := substring(criteria FROM length(operator) + 1);
    ELSE
        -- Default operator is '='
        operator := '=';
        operand := criteria;
    END IF;

    -- Trim any surrounding whitespace
    operand := trim(operand);

    -- Build the SQL query dynamically, casting val and operand to numeric
    sql_query := format(
        'SELECT COUNT(*) FROM unnest($1::%s) AS x(val) WHERE val::numeric %s %s::numeric',
        pg_typeof(arr)::text,
        operator,
        quote_literal(operand)
    );

    EXECUTE sql_query INTO count USING arr;

    RETURN count;
END;
$$;

