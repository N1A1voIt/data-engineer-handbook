CREATE TYPE films AS (
    film text,
    votes INTEGER,
    rating REAL,
    filmid text
);
CREATE TYPE quality_class AS ENUM (
    'star','good','average','bad'
);

CREATE TABLE actors (
    actorid text ,
    actor text,
    films films[],
    quality_class quality_class,
    is_active BOOLEAN,
    year INTEGER,
    PRIMARY KEY (actorid,year)
);