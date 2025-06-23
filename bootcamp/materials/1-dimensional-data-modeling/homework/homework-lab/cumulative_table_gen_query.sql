INSERT INTO actors
WITH actors_year AS(
    SELECT actorid,actor,MAX(year) as year FROM actor_films GROUP BY actorid,actor
)
select actorid,MAX(actor) as actor,
       ARRAY_AGG(
               ROW (
                   film,
                   votes,
                   rating,
                   filmid
                   )::films
       ),
        CASE WHEN  AVG(rating) > 8 THEN 'star'::quality_class
            WHEN avg(rating) > 7 AND avg(rating) <= 8 THEN 'good'::quality_class
            WHEN avg(rating) > 6 and avg(rating) <= 7 THEN 'average'::quality_class
            WHEN avg(rating) <= 6 THEN 'bad'::quality_class END as quality_class,
        CASE WHEN (SELECT year FROM actors_year WHERE actor_films.actorid = actors_year.actorid) = 2021 THEN true ELSE false END as is_active,
        year
from actor_films WHERE year = 2021
group by actorid,year;
