INSERT INTO fct_game_details
WITH deduped_datasets as (
    SELECT game_date_est,
        season,
        home_team_id,
        game_details.*,
        row_number()
        over (partition by game_details.game_id,team_id,player_id order by game_date_est) as row_num
    FROM game_details
        JOIN
    public.games g on g.game_id = game_details.game_id
)
SELECT game_date_est as dim_game_date,
       season as dim_season,
       team_id as dim_team_id,
       player_id as dim_player_id,
       player_name as dim_player_name,
       start_position as dim_start_position,
       COALESCE(position('NWT' in comment) > 0,false) as dim_not_with_team,
       COALESCE(position('DNP' in comment) > 0,false) as dim_did_not_play,
       COALESCE(position('DND' in comment) > 0,false) as dim_not_dress,
       (split_part(min,':',1)::real + split_part(min,':',2)::real/60) as m_minutes,
       fgm as m_fgm,
       fga as m_fga,
       fg3m as m_fg3m,
       fg3a as m_fg3a,
       ftm as m_ftm,
       fta as m_fta,
       ft_pct as m_ft_pct,
       oreb as m_oreb,
       dreb as m_dreb,
       reb as m_reb,
       ast as m_ast,
       stl as m_stl,
       blk as m_blk,
       "TO" as m_turnover,
       pf as m_pf,
       pts as m_pts,
       plus_minus as m_plus_minus
       FROM deduped_datasets WHERE row_num=1;

CREATE TABLE fct_game_details (
    dim_game_date date,
    dim_season INTEGER,
    dim_team_id INTEGER,
    dim_player_id INTEGER,
    dim_player_name text,
    dim_start_position text,
    dim_not_with_team boolean,
    dim_did_not_play boolean,
    dim_not_dress boolean,
    m_minutes real,
    m_fgm integer,
    m_fga integer,
    m_fg3m integer,
    m_fg3a integer,
    m_ftm integer,
    m_fta integer,
    m_ft_pct integer,
    m_oreb integer,
    m_dreb integer,
    m_reb integer,
    m_ast integer,
    m_stl integer,
    m_blk integer,
    m_turnovers integer,
    m_pf integer,
    m_pts integer,
    m_plus_minus integer,
    PRIMARY KEY (dim_game_date,dim_team_id,dim_player_id)
);