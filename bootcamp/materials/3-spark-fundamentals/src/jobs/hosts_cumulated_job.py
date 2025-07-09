from pyspark.sql import SparkSession


sql="""
WITH yesterday_data AS (
    SELECT * FROM hosts_cumulated WHERE date_lim = DATE('2023-01-30')
),today_data as (
    SELECT host as host_id,date_trunc('day',DATE(event_time)) as date_lim FROM events WHERE date_trunc('day',DATE(event_time)) = DATE('2023-01-31') GROUP BY date_lim,host_id
)
SELECT COALESCE(yesterday_data.host_id,today_data.host_id) as host_id
        , COALESCE(dates,ARRAY[]::date[])
              ||
            CASE WHEN today_data.host_id IS NULL OR today_data.date_lim IS NULL THEN ARRAY[]::date[]
            ELSE ARRAY[today_data.date_lim] END as dates,
       yesterday_data.date_lim + interval '1 day' as date_lim
    FROM today_data FULL OUTER JOIN yesterday_data on yesterday_data.host_id = today_data.host_id;
"""


def do_host_cumulation_transformation(spark, dataframe):
    dataframe.createOrReplaceTempView("hosts_cumulated")
    dataframe.createOrReplaceTempView("events")
    return spark.sql(sql)