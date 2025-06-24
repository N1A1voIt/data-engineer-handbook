CREATE TYPE lab_scd_type AS (
    quality_class quality_class,
    is_active boolean,
    start_date date,
    end_date date
);


WITH last_year_scd AS (
    SELECT * FROM actors_history_scd
    WHERE end_date = make_date(2020, 12, 31)
),
historical_scd AS (
    SELECT
        actorid,
        actorname,
        quality_class,
        is_active,
        start_date,
        end_date
    FROM actors_history_scd
    WHERE end_date < make_date(2020, 12, 31)
),
current_year_data AS (
    SELECT * FROM actors
    WHERE year = 2021
),
unchanged_records AS (
    SELECT
        ts.actorid,
        ts.actor as actorname,
        ts.quality_class,
        ts.is_active,
        ls.start_date,
        make_date(ts.year, 12, 31) as end_date
    FROM current_year_data ts
    JOIN last_year_scd ls ON ls.actorid = ts.actorid
    WHERE ts.quality_class = ls.quality_class
    AND ts.is_active = ls.is_active
),
changed_records AS (
    SELECT
        ts.actorid,
        ts.actor as actorname,
        UNNEST(ARRAY[
            ROW(
                ls.quality_class,
                ls.is_active,
                ls.start_date,
                ls.end_date
            )::lab_scd_type,
            ROW(
                ts.quality_class,
                ts.is_active,
                make_date(ts.year, 1, 1),
                make_date(ts.year, 12, 31)
            )::lab_scd_type
        ]) as records
    FROM current_year_data ts
    LEFT JOIN last_year_scd ls ON ls.actorid = ts.actorid
    WHERE (ts.quality_class <> ls.quality_class
        OR ts.is_active <> ls.is_active)
),
unnested_changed_records AS (
    SELECT
        actorid,
        actorname,
        (records::lab_scd_type).quality_class,
        (records::lab_scd_type).is_active,
        (records::lab_scd_type).start_date,
        (records::lab_scd_type).end_date
    FROM changed_records
),
new_records AS (
    SELECT
        ts.actorid,
        ts.actor as actorname,
        ts.quality_class,
        ts.is_active,
        make_date(ts.year, 1, 1) as start_date,
        make_date(ts.year, 12, 31) as end_date
    FROM current_year_data ts
    LEFT JOIN last_year_scd ls ON ts.actorid = ls.actorid
    WHERE ls.actorid IS NULL
)
SELECT * FROM (
    SELECT * FROM historical_scd

    UNION ALL

    SELECT * FROM unchanged_records

    UNION ALL

    SELECT * FROM unnested_changed_records

    UNION ALL

    SELECT * FROM new_records
) a;
