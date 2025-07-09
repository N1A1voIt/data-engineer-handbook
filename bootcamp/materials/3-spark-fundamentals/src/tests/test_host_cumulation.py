from collections import namedtuple
from datetime import datetime, date
from chispa import assert_df_equality
from src.jobs.hosts_cumulated_job import do_host_cumulation_transformation

Events = namedtuple("Events", "url referrer user_id device_id host event_time")
HostsCumulated = namedtuple("HostsCumulated", "host_id dates date_lim")


def test_scd_generation(spark):
    source_data = [
        # Historical (hosts_cumulated)
        HostsCumulated("host1", [date(2023, 1, 28), date(2023, 1, 30)], date(2023, 1, 30)),
        HostsCumulated("host2", [date(2023, 1, 29)], date(2023, 1, 30)),
        # Incoming events (events)
        Events("url1", "ref1", "user1", "device1", "host1", datetime(2023, 1, 31, 10, 0)),
        Events("url2", "ref2", "user2", "device2", "host3", datetime(2023, 1, 31, 12, 0)),
    ]
    source_df = spark.createDataFrame(source_data)

    actual_df = do_host_cumulation_transformation(spark, source_df)
    expected_data = [
        HostsCumulated("host1", [date(2023, 1, 28), date(2023, 1, 30), date(2023, 1, 31)], date(2023, 1, 31)),
        HostsCumulated("host2", [date(2023, 1, 29)], date(2023, 1, 31)),
        HostsCumulated("host3", [date(2023, 1, 31)], date(2023, 1, 31)),
    ]
    expected_df = spark.createDataFrame(expected_data)
    assert_df_equality(actual_df, expected_df)