from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    broadcast, col, to_timestamp, sum, count, countDistinct
)
from pyspark.sql.utils import AnalysisException

# Initialize Spark session
spark = SparkSession.builder \
    .appName("HaloAnalytics") \
    .config("spark.driver.memory", "6g") \
    .config("spark.sql.shuffle.partitions", "100") \
    .getOrCreate()

# Disable automatic broadcast join
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")

# Load input data with error handling
try:
    match_details_df = spark.read.option("header", "true").csv("/home/iceberg/data/match_details.csv")
    medals_matches_players_df = spark.read.option("header", "true").csv("/home/iceberg/data/medals_matches_players.csv")
    matches_df = spark.read.option("header", "true").csv("/home/iceberg/data/matches_copy.csv")
    medals_df = spark.read.option("header", "true").csv("/home/iceberg/data/medals.csv")
    maps_df = spark.read.option("header", "true").csv("/home/iceberg/data/maps.csv")
except AnalysisException as e:
    print(f"Error loading data: {e}")
    spark.stop()
    exit()

# Drop existing tables if they exist
spark.sql("DROP TABLE IF EXISTS bootcamp.matches_bucketed")
spark.sql("DROP TABLE IF EXISTS bootcamp.match_details_bucketed")
spark.sql("DROP TABLE IF EXISTS bootcamp.medals_matches_players_bucketed")

# Create bucketed Iceberg tables
spark.sql("""
CREATE TABLE IF NOT EXISTS bootcamp.matches_bucketed (
    match_id STRING,
    mapid STRING,
    is_team_game BOOLEAN,
    playlist_id STRING,
    completion_date TIMESTAMP
)
USING iceberg
PARTITIONED BY (completion_date, bucket(16, match_id))
""")

spark.sql("""
CREATE TABLE IF NOT EXISTS bootcamp.match_details_bucketed (
    match_id STRING,
    player_gamertag STRING,
    player_total_kills INT,
    player_total_deaths INT
)
USING iceberg
PARTITIONED BY (bucket(16, match_id))
""")

spark.sql("""
CREATE TABLE IF NOT EXISTS bootcamp.medals_matches_players_bucketed (
    match_id STRING,
    player_gamertag STRING,
    medal_id STRING,
    count INT
)
USING iceberg
PARTITIONED BY (bucket(16, match_id))
""")

# Cast and write the bucketed tables
match_details_df.select(
    "match_id", "player_gamertag",
    col("player_total_kills").cast("int"),
    col("player_total_deaths").cast("int")
).write.mode("overwrite").bucketBy(16, "match_id").saveAsTable("bootcamp.match_details_bucketed")

medals_matches_players_df.select(
    "match_id", "player_gamertag", "medal_id",
    col("count").cast("int")
).write.mode("overwrite").bucketBy(16, "match_id").saveAsTable("bootcamp.medals_matches_players_bucketed")

matches_df.select(
    "match_id", "mapid",
    col("is_team_game").cast("boolean"),
    "playlist_id",
    to_timestamp("completion_date", "yyyy-MM-dd HH:mm:ss.SSSSSS").alias("completion_date")
).write.mode("overwrite") \
    .partitionBy("completion_date") \
    .bucketBy(16, "match_id") \
    .saveAsTable("bootcamp.matches_bucketed")

# Read bucketed tables back in
matches = spark.table("bootcamp.matches_bucketed")
match_details = spark.table("bootcamp.match_details_bucketed")
medal_matches = spark.table("bootcamp.medals_matches_players_bucketed")

# Broadcast join maps to matches
matches_with_maps = matches.join(broadcast(maps_df), on="mapid", how="left")
matches_with_maps.select("match_id", "map_name", "playlist_id").show(5)

# Broadcast join medals to medal_matches
medal_matches_named = medal_matches.join(broadcast(medals_df), on="medal_id", how="left")

# Aggregation 1: Which player averages the most kills per game?
most_kills_per_game = match_details.groupBy("player_gamertag") \
    .agg((sum("player_total_kills") / countDistinct("match_id")).alias("avg_kills_per_game")) \
    .orderBy(col("avg_kills_per_game").desc())

most_kills_per_game.show(5)

# 🔍 Aggregation 2: Which playlist gets played the most?
most_played_playlists = matches.groupBy("playlist_id") \
    .agg(count("*").alias("times_played")) \
    .orderBy(col("times_played").desc())

most_played_playlists.show(5)

# 🔍 Aggregation 3: Which map gets played the most?
most_played_maps = matches.groupBy("mapid") \
    .agg(count("*").alias("times_played")) \
    .orderBy(col("times_played").desc())

most_played_maps.show(5)

# 🔍 Aggregation 4: Which map do players get the most Killing Spree medals on?
killing_spree_medals = medal_matches_named.filter(col("medal_name") == "Killing Spree")

killing_spree_with_map = killing_spree_medals.join(matches, on="match_id", how="inner")

most_killing_spree_by_map = killing_spree_with_map.groupBy("mapid") \
    .agg(sum("count").alias("total_killing_sprees")) \
    .orderBy(col("total_killing_sprees").desc())

most_killing_spree_by_map.show(5)

# 🧪 Optional: sortWithinPartitions test
matches.sortWithinPartitions("playlist_id").write.mode("overwrite").parquet("/tmp/matches_sorted_by_playlist")
matches.sortWithinPartitions("mapid").write.mode("overwrite").parquet("/tmp/matches_sorted_by_map")

# ✅ Clean exit
spark.stop()
