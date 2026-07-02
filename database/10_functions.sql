-- =============================================================================
-- IT Management System - SQL Functions
-- =============================================================================

DELIMITER //

-- 1. fn_calc_performance_rating - Calculate performance rating based on score
CREATE OR REPLACE FUNCTION fn_calc_performance_rating(p_score DECIMAL(5,2))
RETURNS VARCHAR(30)
DETERMINISTIC
READS SQL DATA
BEGIN
    IF p_score >= 95 THEN
        RETURN 'Excellent';
    ELSEIF p_score >= 85 THEN
        RETURN 'Very Good';
    ELSEIF p_score >= 75 THEN
        RETURN 'Good';
    ELSEIF p_score >= 60 THEN
        RETURN 'Need Improvement';
    ELSE
        RETURN 'Unsatisfactory';
    END IF;
END//

-- 2. fn_calc_duration - Calculate trip duration in human-readable format
CREATE OR REPLACE FUNCTION fn_calc_duration(p_departure VARCHAR(10), p_arrival VARCHAR(10))
RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE dep_min INT;
    DECLARE arr_min INT;
    DECLARE diff_min INT;
    DECLARE hours INT;
    DECLARE mins INT;

    IF p_departure IS NULL OR p_arrival IS NULL OR p_departure = '' OR p_arrival = '' THEN
        RETURN '';
    END IF;

    SET dep_min = CAST(SUBSTRING_INDEX(p_departure, ':', 1) AS UNSIGNED) * 60
                + CAST(SUBSTRING_INDEX(p_departure, ':', -1) AS UNSIGNED);
    SET arr_min = CAST(SUBSTRING_INDEX(p_arrival, ':', 1) AS UNSIGNED) * 60
                + CAST(SUBSTRING_INDEX(p_arrival, ':', -1) AS UNSIGNED);

    IF arr_min <= dep_min THEN
        SET arr_min = arr_min + 1440;
    END IF;

    SET diff_min = arr_min - dep_min;
    IF diff_min > 1440 THEN
        RETURN '';
    END IF;

    SET hours = diff_min DIV 60;
    SET mins = diff_min MOD 60;

    IF hours > 0 AND mins > 0 THEN
        RETURN CONCAT(hours, 'h ', mins, 'm');
    ELSEIF hours > 0 THEN
        RETURN CONCAT(hours, 'h');
    ELSE
        RETURN CONCAT(mins, 'm');
    END IF;
END//

-- 3. fn_calc_layover - Calculate layover duration from departure to departure from station
CREATE OR REPLACE FUNCTION fn_calc_layover(
    p_departure_time VARCHAR(10),
    p_departure_from_station VARCHAR(10)
)
RETURNS VARCHAR(10)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE dep_min INT;
    DECLARE sta_min INT;
    DECLARE diff_min INT;

    IF p_departure_time IS NULL OR p_departure_from_station IS NULL
       OR p_departure_time = '' OR p_departure_from_station = '' THEN
        RETURN '';
    END IF;

    SET dep_min = CAST(SUBSTRING_INDEX(p_departure_time, ':', 1) AS UNSIGNED) * 60
                + CAST(SUBSTRING_INDEX(p_departure_time, ':', -1) AS UNSIGNED);
    SET sta_min = CAST(SUBSTRING_INDEX(p_departure_from_station, ':', 1) AS UNSIGNED) * 60
                + CAST(SUBSTRING_INDEX(p_departure_from_station, ':', -1) AS UNSIGNED);

    IF sta_min < dep_min THEN
        RETURN '00:00';
    END IF;

    SET diff_min = sta_min - dep_min;
    RETURN CONCAT(LPAD(diff_min DIV 60, 2, '0'), ':', LPAD(diff_min MOD 60, 2, '0'));
END//

-- 4. fn_calc_delay_minutes - Calculate delay in minutes
CREATE OR REPLACE FUNCTION fn_calc_delay_minutes(
    p_arrival_at_station VARCHAR(10),
    p_departure_from_station VARCHAR(10)
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE arr_min INT;
    DECLARE dep_min INT;

    IF p_arrival_at_station IS NULL OR p_departure_from_station IS NULL
       OR p_arrival_at_station = '' OR p_departure_from_station = '' THEN
        RETURN 0;
    END IF;

    SET arr_min = CAST(SUBSTRING_INDEX(p_arrival_at_station, ':', 1) AS UNSIGNED) * 60
                + CAST(SUBSTRING_INDEX(p_arrival_at_station, ':', -1) AS UNSIGNED);
    SET dep_min = CAST(SUBSTRING_INDEX(p_departure_from_station, ':', 1) AS UNSIGNED) * 60
                + CAST(SUBSTRING_INDEX(p_departure_from_station, ':', -1) AS UNSIGNED);

    IF dep_min < arr_min THEN
        RETURN 0;
    END IF;

    RETURN dep_min - arr_min;
END//

-- 5. fn_get_permission_codes_for_role - Get all permission codes for a given role
CREATE OR REPLACE FUNCTION fn_get_permission_codes_for_role(p_role_id INT)
RETURNS JSON
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE result JSON;
    SELECT JSON_ARRAYAGG(p.code)
    INTO result
    FROM role_permissions rp
    JOIN permissions p ON rp.permission_id = p.id
    WHERE rp.role_id = p_role_id AND p.deleted_at IS NULL;
    RETURN COALESCE(result, JSON_ARRAY());
END//

-- 6. fn_get_user_permissions - Get all permission codes for a user (via role)
CREATE OR REPLACE FUNCTION fn_get_user_permissions(p_user_id INT)
RETURNS JSON
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_role_id INT;
    SELECT role_id INTO v_role_id FROM users WHERE id = p_user_id;
    IF v_role_id IS NULL THEN
        RETURN JSON_ARRAY();
    END IF;
    RETURN fn_get_permission_codes_for_role(v_role_id);
END//

DELIMITER ;
