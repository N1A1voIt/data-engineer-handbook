create table fact_host_activity_reduced (
    month date,
    host text,
    hit_array bit(32),
    unique_visitors INTEGER,
    PRIMARY KEY (month,host)
);
create table fact_host_activity_reduced_dbd (
    day date,
    host text,
    hit_array bit(32),
    unique_visitors INTEGER,
    PRIMARY KEY (day,host)
);
INSERT INTO fact_host_activity_reduced
WITH visitors_count AS (
    SELECT date_trunc('month',DATE(event_time)) as month,host,count(DISTINCT user_id) as unique_visitors FROM events GROUP BY month,host
), hosts_activity_tracking as (
    SELECT
        host_id,
         date_lim - DATE(date_series) days_since,
        dates @> ARRAY[DATE(t.date_series)] as is_active,
        date_lim,date_series
        FROM (SELECT host_id,dates,date_lim FROM hosts_cumulated WHERE date_trunc('month',date_lim) = DATE('2023-01-01')) as host_cum
            CROSS JOIN
            (SELECT generate_series('2023-01-01','2023-01-31',interval '1 day') as date_series) as t
)
SELECT month,host_id as host,sum(CASE WHEN is_active THEN pow(2,32 - days_since) ELSE 0 END)::bigint::bit(32) as hit_array,unique_visitors
FROM hosts_activity_tracking JOIN visitors_count ON visitors_count.host = host_id
 WHERE date_lim = DATE('2023-01-31') GROUP BY host_id,month,unique_visitors;

INSERT INTO fact_host_activity_reduced_dbd
WITH visitors_count AS (
    SELECT date_trunc('day',DATE(event_time)) as day,host,count(DISTINCT user_id) as unique_visitors
    FROM events WHERE date_trunc('day',DATE(event_time)) = DATE('2023-01-05') GROUP BY day,host
), hosts_activity_tracking as (
    SELECT
        host_id,
         date_lim - DATE(date_series) days_since,
        dates @> ARRAY[DATE(t.date_series)] as is_active,
        date_lim,date_series
        FROM (SELECT host_id,dates,date_lim FROM hosts_cumulated WHERE date_trunc('day',date_lim) = DATE('2023-01-05')) as host_cum
            CROSS JOIN
            (SELECT generate_series('2023-01-01','2023-01-31',interval '1 day') as date_series) as t
)
SELECT day,host_id as host,sum(CASE WHEN is_active THEN pow(2,32 - days_since) ELSE 0 END)::bigint::bit(32) as hit_array,unique_visitors
FROM hosts_activity_tracking JOIN visitors_count ON visitors_count.host = host_id
 WHERE date_lim = DATE('2023-01-05') GROUP BY host_id,day,unique_visitors;