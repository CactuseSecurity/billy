--------------------------------------------------------------------------------------
-- BASIC FUNCTIONS
----------------------------------------------------
-- FUNCTION:  is_numeric
-- Zweck:     ist ein String eine reine Zahl?
-- Parameter: VARCHAR
-- RETURNS:   BOOLEAN
--
CREATE OR REPLACE FUNCTION is_numeric (varchar)
    RETURNS boolean
    AS $$
DECLARE
    input ALIAS FOR $1;
BEGIN
    RETURN (input ~ '[0-9]');
END;
$$
LANGUAGE plpgsql;
