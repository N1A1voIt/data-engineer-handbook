  SELECT player_name,
         (UNNEST(seasons)::season_stats).* -- CROSS JOIN UNNEST
         -- / LATERAL VIEW EXPLODE
  FROM players
  WHERE current_season = 1998
  AND player_name = 'Michael Jordan';