WITH yesterday AS (
    SELECT * FROM users_cumulated
    WHERE date = DATE('2023-01-30')
),
    today AS (
          SELECT CAST(user_id AS TEXT),
                 DATE_TRUNC('day', DATE(CAST(event_time AS timestamp))) AS today_date,
                 COUNT(1) AS num_events FROM events
            WHERE DATE_TRUNC('day', DATE(CAST(event_time AS timestamp))) = DATE('2023-01-31')
            AND user_id IS NOT NULL
         GROUP BY user_id,  DATE_TRUNC('day', DATE(CAST(event_time AS timestamp)))
    )
-- INSERT INTO users_cumulated
SELECT
       COALESCE(t.user_id, y.user_id),
       COALESCE(y.dates_active,
           ARRAY[]::DATE[])
            || CASE WHEN
                t.user_id IS NOT NULL
                THEN ARRAY[t.today_date]
                ELSE ARRAY[]::DATE[]
                END AS date_list,
       COALESCE(t.today_date, y.date + Interval '1 day') as date
FROm yesterday y
    FULL OUTER JOIN
    today t ON t.user_id = y.user_id;