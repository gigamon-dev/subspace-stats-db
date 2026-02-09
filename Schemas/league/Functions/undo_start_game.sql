create or replace function league.undo_start_game(
	 p_season_game_id league.season_game.season_game_id%type
)
returns integer
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Undo the start of a league game (change the state from "In Progress" back to "Pending").
This is intended to be called after a game has been announced via league.start_game
and a referee wants to undo it, perhaps because the game should be rescheduled.

Parmeters:
p_season_game_id - The season game to uninitialize.

Returns: 
	200 - success 
	404 - not found (invalid p_season_game_id)
	409 - failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state)
(based on http status codes)

Usage:
select * from league.undo_start_game(23);
select * from league.undo_start_game(999999999); -- test 404
--select * from league.season_game;
--update league.season_game set game_status_id = 1 where season_game_id = 23
select * from league.game_status
*/

begin
	update league.season_game as sg
	set game_status_id = 1 -- pending
	where sg.season_game_id = p_season_game_id
		and exists(
			select *
			from league.season as s
			where s.season_id = sg.season_id
				and s.start_date is not null -- season is started
				and s.end_date is null -- season has not ended
		)
		and sg.game_status_id = 2; -- in progress

	if FOUND then
		return 200; -- success
	elsif not exists(select * from league.season_game where season_game_id = p_season_game_id) then
		return 404; -- not found (invalid p_season_game_id)
	else
		return 409; -- failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state)
	end if;
end;

$$;

alter function league.undo_start_game owner to ss_developer;

revoke all on function league.undo_start_game from public;

grant execute on function league.undo_start_game to ss_zone_server;
