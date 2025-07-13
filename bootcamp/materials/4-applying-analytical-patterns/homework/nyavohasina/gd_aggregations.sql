
WITH game_details_simulation AS (
    SELECT 
        player_name,
        season,
        'TEAM_' || (ROW_NUMBER() OVER (ORDER BY player_name) % 30 + 1) as team_abbreviation,
        pts,
        reb,
        ast,
        gp,
        ROUND(gp * 0.5) as wins
    FROM player_seasons
    WHERE pts IS NOT NULL
),

aggregated_stats AS (
    SELECT 
        player_name,
        team_abbreviation,
        season,
        SUM(pts) as total_points,
        SUM(reb) as total_rebounds,
        SUM(ast) as total_assists,
        SUM(gp) as total_games,
        SUM(wins) as total_wins,
        GROUPING(player_name) as player_grouping,
        GROUPING(team_abbreviation) as team_grouping,
        GROUPING(season) as season_grouping
    FROM game_details_simulation
    GROUP BY GROUPING SETS (
        (player_name, team_abbreviation),
        (player_name, season),
        (team_abbreviation),
        ()
    )
)

SELECT 
    CASE 
        WHEN player_grouping = 0 AND team_grouping = 0 AND season_grouping = 1 
        THEN 'Player-Team Analysis'
        WHEN player_grouping = 0 AND team_grouping = 1 AND season_grouping = 0 
        THEN 'Player-Season Analysis'
        WHEN player_grouping = 1 AND team_grouping = 0 AND season_grouping = 1 
        THEN 'Team Analysis'
        WHEN player_grouping = 1 AND team_grouping = 1 AND season_grouping = 1 
        THEN 'Grand Total'
        ELSE 'Other'
    END as analysis_type,
    player_name,
    team_abbreviation,
    season,
    total_points,
    total_rebounds,
    total_assists,
    total_games,
    total_wins
FROM aggregated_stats
ORDER BY analysis_type, total_points DESC;





SELECT 
    player_name,
    team_abbreviation,
    SUM(pts) as total_points_for_team
FROM game_details_simulation
GROUP BY player_name, team_abbreviation
ORDER BY total_points_for_team DESC
LIMIT 10;


SELECT 
    player_name,
    season,
    SUM(pts) as total_points_in_season
FROM game_details_simulation
GROUP BY player_name, season
ORDER BY total_points_in_season DESC
LIMIT 10;


SELECT 
    team_abbreviation,
    SUM(wins) as total_wins
FROM game_details_simulation
GROUP BY team_abbreviation
ORDER BY total_wins DESC
LIMIT 10;