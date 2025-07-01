 CREATE TABLE users_cumulated (
     user_id text,
     dates_active DATE[],
     date DATE,
     PRIMARY KEY (user_id, date)
 );
