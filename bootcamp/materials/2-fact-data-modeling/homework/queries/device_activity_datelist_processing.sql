INSERT INTO user_devices_cumulated
WITH event_cpl as (
    SELECT events.*, devices.browser_type
        FROM events
        JOIN devices
        ON events.device_id = devices.device_id
) , yesterday_devices_cumulated as (
    SELECT * FROM user_devices_cumulated WHERE date = DATE('2023-01-05')
) , today as (
    SELECT
        CAST(user_id AS text),
        date_trunc('day',DATE(event_time)) as event_date,
        browser_type,
        count(1) number_event
    FROM event_cpl
    WHERE date_trunc('day',DATE(event_time)) = DATE('2023-01-06') AND user_id IS NOT NULL AND browser_type IS not null
    GROUP BY user_id,date_trunc('day',DATE(event_time)),browser_type
)
SELECT
    COALESCE(t.user_id,y.user_id) as user_id,
    t.browser_type,
    COALESCE(y.dates_active,ARRAY[]::date[]) ||
        CASE WHEN t.user_id IS NOT NULL THEN ARRAY[event_date]
        WHEN t.browser_type IS NULL OR t.user_id IS NULL THEN ARRAY[]::date[]
        END as dates_active,
    event_date as date
FROM today t
    FULL
        OUTER JOIN yesterday_devices_cumulated y
            ON y.user_id = t.user_id WHERE t.browser_type IS NOT  NULL;