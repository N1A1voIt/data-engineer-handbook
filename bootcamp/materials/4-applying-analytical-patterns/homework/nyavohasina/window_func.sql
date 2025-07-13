WITH game_details_simulation AS (
    SELECT
        'Game_' || ROW_NUMBER() OVER (ORDER BY player_name, season) as game_id,
        player_name,
        season,
        'TEAM_' || (ROW_NUMBER() OVER (ORDER BY player_name) % 30 + 1) as team_abbreviation,
        pts / GREATEST(gp, 1) as points_per_game,
        CASE WHEN RANDOM() > 0.5 THEN 1 ELSE 0 END as team_win,
        ROW_NUMBER() OVER (PARTITION BY player_name, season ORDER BY RANDOM()) as game_number
    FROM player_seasons
    WHERE pts IS NOT NULL AND gp > 0
),

team_game_sequence AS (
    SELECT
        team_abbreviation,
        game_id,
        team_win,
        ROW_NUMBER() OVER (PARTITION BY team_abbreviation ORDER BY game_id) as game_sequence
    FROM game_details_simulation
),

team_90_game_windows AS (
    SELECT
        team_abbreviation,
        game_sequence,
        team_win,
        SUM(team_win) OVER (
            PARTITION BY team_abbreviation
            ORDER BY game_sequence
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) as wins_in_90_games,
        COUNT(*) OVER (
            PARTITION BY team_abbreviation
            ORDER BY game_sequence
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) as games_in_window
    FROM team_game_sequence
),

max_team_wins_90_games AS (
    SELECT
        team_abbreviation,
        MAX(wins_in_90_games) as max_wins_in_90_games
    FROM team_90_game_windows
    WHERE games_in_window = 90
    GROUP BY team_abbreviation
),



lebron_games AS (
    SELECT
        player_name,
        game_id,
        game_number,
        points_per_game,
        CASE WHEN points_per_game > 10 THEN 1 ELSE 0 END as scored_over_10
    FROM game_details_simulation
    WHERE player_name = 'LeBron James'
    ORDER BY game_number
),

lebron_streaks AS (
    SELECT
        player_name,
        game_id,
        game_number,
        points_per_game,
        scored_over_10,
        ROW_NUMBER() OVER (ORDER BY game_number) -
        ROW_NUMBER() OVER (PARTITION BY scored_over_10 ORDER BY game_number) as streak_group
    FROM lebron_games
),

lebron_consecutive_streaks AS (
    SELECT
        player_name,
        streak_group,
        scored_over_10,
        COUNT(*) as consecutive_games,
        MIN(game_number) as streak_start,
        MAX(game_number) as streak_end
    FROM lebron_streaks
    WHERE scored_over_10 = 1
    GROUP BY player_name, streak_group, scored_over_10
)


SELECT
    team_abbreviation,
    max_wins_in_90_games as most_wins_in_90_games
FROM max_team_wins_90_games
ORDER BY max_wins_in_90_games DESC
LIMIT 10;


SELECT
    player_name,
    MAX(consecutive_games) as longest_consecutive_games_over_10_points
FROM lebron_consecutive_streaks
GROUP BY player_name;


SELECT
    player_name,
    consecutive_games,
    streak_start,
    streak_end
FROM lebron_consecutive_streaks
ORDER BY consecutive_games DESC
LIMIT 10;


WITH player_game_analysis AS (
    SELECT
        player_name,
        season,
        game_number,
        points_per_game,
        SUM(team_win) OVER (
            PARTITION BY team_abbreviation
            ORDER BY game_number
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) as rolling_90_game_wins,
        CASE WHEN points_per_game > 10 THEN 1 ELSE 0 END as over_10_points,
        LAG(CASE WHEN points_per_game > 10 THEN 1 ELSE 0 END) OVER (
            PARTITION BY player_name
            ORDER BY game_number
        ) as prev_over_10
    FROM game_details_simulation
)

SELECT
    player_name,
    season,
    COUNT(*) as games_analyzed,
    MAX(rolling_90_game_wins) as max_90_game_wins,
    SUM(over_10_points) as total_games_over_10
FROM player_game_analysis
GROUP BY player_name, season
ORDER BY max_90_game_wins DESC, total_games_over_10 DESC;