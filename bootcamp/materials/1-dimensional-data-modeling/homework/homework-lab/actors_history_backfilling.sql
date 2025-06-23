WITH unnested_films AS (
    SELECT 
        actorid,
        actor,
        year,
        lead(year) over (partition by actorid ORDER BY actor,year) as next_year,
        (unnest(films)).rating as film_rating
    FROM actors
)
SELECT 
    actorid,
    actor as actorname,
    CASE 
        WHEN avg(film_rating) > 8 THEN 'star'::quality_class
        WHEN avg(film_rating) > 7 AND avg(film_rating) <= 8 THEN 'good'::quality_class
        WHEN avg(film_rating) > 6 AND avg(film_rating) <= 7 THEN 'average'::quality_class
        WHEN avg(film_rating) <= 6 THEN 'bad'::quality_class 
    END as quality_class,
    CASE WHEN year <> (SELECT MAX(year) FROM actors) THEN false ELSE true END as is_active,
    make_date(year,1,1) as start_date,
    make_date(coalesce(next_year,9999),12,31) as end_date
FROM unnested_films 
GROUP BY actorid, actor, year,next_year;
