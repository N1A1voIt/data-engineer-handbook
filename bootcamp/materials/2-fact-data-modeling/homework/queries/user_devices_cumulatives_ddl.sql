CREATE TABLE user_devices_cumulated (
    user_id text,
    browser_type text,
    dates_active date[],
    date date,
    PRIMARY KEY (user_id,browser_type,date)
);