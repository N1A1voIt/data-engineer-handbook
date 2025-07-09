from collections import namedtuple
from datetime import date

from chispa import assert_df_equality
from pyspark import Row

from src.jobs.actors_history_scd import actors_history_transformation

Actors = namedtuple(
    "Actors", "actor_id actor films quality_class is_active year")

def test_actors_history(spark):
    source_data = [
        Actors(1, "Actor A", [Row(rating=9), Row(rating=8.5)], None, None, 2022),
        Actors(1, "Actor A", [Row(rating=6.5), Row(rating=7)], None, None, 2023),
        Actors(2, "Actor B", [Row(rating=5.5), Row(rating=6)], None, None, 2023),
    ]
    source_df = spark.createDataFrame(source_data)
    output = actors_history_transformation(spark,source_df)

    expected_data = [
        Row(actorid=1, actorname="Actor A", start_date=date(2022, 1, 1), end_date=date(2023, 12, 31),
            quality_class="star", is_active=False),
        Row(actorid=1, actorname="Actor A", start_date=date(2023, 1, 1), end_date=date(9999, 12, 31),
            quality_class="average", is_active=True),
        Row(actorid=2, actorname="Actor B", start_date=date(2023, 1, 1), end_date=date(9999, 12, 31),
            quality_class="bad", is_active=True),
    ]
    expected_df = spark.createDataFrame(expected_data)
    assert_df_equality(output, expected_df,ignore_nullable=True)