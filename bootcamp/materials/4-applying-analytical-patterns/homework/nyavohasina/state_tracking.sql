WITH player_seasons_with_activity AS (
    SELECT 
        player_name,
        season,
        CASE WHEN pts IS NOT NULL THEN 1 ELSE 0 END as is_active
    FROM player_seasons
),

player_season_states AS (
    SELECT 
        player_name,
        season,
        is_active,
        LAG(is_active, 1, 0) OVER (PARTITION BY player_name ORDER BY season) as previous_active,
        ROW_NUMBER() OVER (PARTITION BY player_name ORDER BY season) as season_number
    FROM player_seasons_with_activity
),

state_changes AS (
    SELECT 
        player_name,
        season,
        is_active,
        previous_active,
        season_number,
        CASE
            WHEN season_number = 1 AND is_active = 1 THEN 'New'
            WHEN previous_active = 1 AND is_active = 0 THEN 'Retired'
            WHEN previous_active = 1 AND is_active = 1 THEN 'Continued Playing'
            WHEN previous_active = 0 AND is_active = 1 THEN 'Returned from Retirement'
            WHEN previous_active = 0 AND is_active = 0 THEN 'Stayed Retired'
            ELSE 'Unknown'
        END as state_change
    FROM player_season_states
)

SELECT 
    player_name,
    season,
    state_change,
    is_active,
    previous_active
FROM state_changes
WHERE state_change != 'Unknown'
ORDER BY player_name, season;

WITH player_activity_by_season AS (
    SELECT DISTINCT
        player_name,
        current_season,
        is_active,
        LAG(is_active) OVER (PARTITION BY player_name ORDER BY current_season) as previous_active,
        ROW_NUMBER() OVER (PARTITION BY player_name ORDER BY current_season) as season_rank
    FROM players
),

player_state_changes AS (
    SELECT 
        player_name,
        current_season,
        is_active,
        previous_active,
        CASE 
            WHEN season_rank = 1 AND is_active = TRUE THEN 'New'
            WHEN previous_active = TRUE AND is_active = FALSE THEN 'Retired'
            WHEN previous_active = TRUE AND is_active = TRUE THEN 'Continued Playing'
            WHEN previous_active = FALSE AND is_active = TRUE THEN 'Returned from Retirement'
            WHEN previous_active = FALSE AND is_active = FALSE THEN 'Stayed Retired'
            ELSE 'Unknown'
        END as state_change
    FROM player_activity_by_season
)

SELECT 
    player_name,
    current_season,
    state_change,
    is_active as current_status,
    previous_active as previous_status
FROM player_state_changes
WHERE state_change != 'Unknown'
ORDER BY player_name, current_season;