create or replace function league.delete_season_game(
	p_season_game_id league.season_game.season_game_id%type
)
returns void
language sql
security definer
set search_path = league, ss, pg_temp
as
$$

/*
*/

delete from league.season_game_team
where season_game_id = p_season_game_id;

delete from league.season_game
where season_game_id = p_season_game_id;

$$;

alter function league.delete_season_game owner to ss_developer;

revoke all on function league.delete_season_game from public;

grant execute on function league.delete_season_game to ss_web_server;
