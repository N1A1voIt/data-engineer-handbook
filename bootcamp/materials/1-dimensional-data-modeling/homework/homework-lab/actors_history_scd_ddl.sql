CREATE TABLE actors_history_scd (
    actorid text,
    actorname text,
    start_date date,
    end_date date DEFAULT '9999-10-21',
    quality_class quality_class,
    is_active boolean,
    PRIMARY KEY (actorid,start_date)
);