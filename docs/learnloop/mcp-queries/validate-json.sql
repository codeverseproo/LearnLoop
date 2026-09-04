-- ============================================
-- JSON Validation Queries
-- ============================================
-- Validates JSON structure before INSERT/UPDATE operations

-- Validate learning_style_json structure
-- Returns 1 if valid, 0 if invalid
SELECT CASE
    WHEN :json_input IS NULL THEN 1
    WHEN json_valid(:json_input) = 0 THEN 0
    WHEN json_extract(:json_input, '$.primary') IS NULL THEN 0
    ELSE 1
END AS is_valid;

-- Extract and validate learning style fields
SELECT
    goal_id,
    json_extract(learning_style_json, '$.primary') AS primary_style,
    json_extract(learning_style_json, '$.secondary') AS secondary_style,
    json_extract(learning_style_json, '$.preferences') AS preferences
FROM goal_meta
WHERE learning_style_json IS NOT NULL
  AND json_valid(learning_style_json) = 1;

-- Find invalid JSON entries (for data quality audit)
SELECT goal_id, learning_style_json
FROM goal_meta
WHERE learning_style_json IS NOT NULL
  AND (
    json_valid(learning_style_json) = 0
    OR json_extract(learning_style_json, '$.primary') IS NULL
  );
