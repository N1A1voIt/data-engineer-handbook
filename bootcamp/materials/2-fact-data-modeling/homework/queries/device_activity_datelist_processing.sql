INSERT INTO user_devices_cumulated
WITH event_cpl as (
    SELECT events.*, devices.browser_type
        FROM events
        JOIN devices
        ON events.device_id = devices.device_id
) , yesterday_devices_cumulated as (
    SELECT * FROM user_devices_cumulated WHERE date = DATE('2023-01-30')
) , today as (
    SELECT
        CAST(user_id AS text),
        date_trunc('day',DATE(event_time)) as event_date,
        browser_type,
        count(1) number_event
    FROM event_cpl
    WHERE date_trunc('day',DATE(event_time)) = DATE('2023-01-31') AND user_id IS NOT NULL AND browser_type IS not null
    GROUP BY user_id,date_trunc('day',DATE(event_time)),browser_type
)
SELECT
    COALESCE(t.user_id,y.user_id) as user_id,
    COALESCE(t.browser_type,y.browser_type) as browser_type,
    COALESCE(y.dates_active,ARRAY[]::date[]) ||
        CASE WHEN t.user_id IS NOT NULL THEN ARRAY[event_date]
        WHEN t.user_id IS NULL THEN ARRAY[]::date[]
        END as dates_active,
    COALESCE(event_date,y.date + interval '1 day') as date
FROM today t
    FULL
        OUTER JOIN yesterday_devices_cumulated y
            ON y.user_id = t.user_id AND y.browser_type = t.browser_type
 ORDER BY user_id,browser_type;

CREATE TABLE user_devices_cumulated_int (
    user_id text,
    browser_type text,
    dates_active_int text,
    date date,
    PRIMARY KEY (user_id,browser_type,date)
);

INSERT INTO user_devices_cumulated_int
WITH activity_tracking as (
    SELECT
        dates_active @> ARRAY[DATE(date_series)] as is_active,
         extract ( DAY FROM date - t.date_series) as days_since,
         user_id,browser_type,date
        FROM user_devices_cumulated CROSS JOIN
    (SELECT generate_series('2023-01-01','2023-01-31' ,interval '1day') as date_series) as t
),
    sum_activity as (
        SELECT user_id,browser_type,sum(
                    CASE
                        WHEN is_active THEN POW(2, 32 - days_since)
                    ELSE 0 END
               )::bigint::bit(32) as dates_active_int,date FROM activity_tracking GROUP BY user_id,browser_type,date
    ) select * FROM sum_activity;

