INSERT INTO vertices
SELECT
    player_id as identifier,
    'player'::vertex_type as type,
    json_build_object(
        'player_name', MIN(player_name) ,
        'number_of_games', COUNT(1),
        'total_points',sum(pts),
        'teams',array_agg(team_id)
    )
    FROM game_details group by player_id;