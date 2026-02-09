create or replace function league.start_game(
	 p_season_game_id league.season_game.season_game_id%type
	,p_force boolean
)
returns table(
	 code integer
	,game_json json
)
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Starts a league game.
This is intended to be called by a zone server when announcing a game.
This could happen by an automated process based on league.season_game.game_timestamp, 
or manually by an league referee (perhaps a command like: ?startleaguegame <season game id>).
The return value tells the zone if it should continue or abort.

TODO: If we want to allow captains to start a game, then we'll have to also check the game_timestamp too.

Normally, the game will be in the "Pending" state when this is called.
Alternatively, if the game already is "In Progress", it can be overriden with the p_force parameter.
This might be useful if the game was rescheduled or there was a problem such as the zone server crashing.
The idea is that a league referee could force restart a match (perhaps a command like: ?startleaguegame -f <season game id>).

Parmeters:
p_season_game_id - The season game to start.
p_force - True to force the update (when already "In Progress")

Returns: a single record
code: 
	200 - success 
	404 - not found (invalid p_season_game_id)
	409 - failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state and/or p_force not being true)
(based on http status codes)

game_json:
	When code = 200 (success), json containing information about the game.
	See the league.get_season_game function for details.
	The league game mode logic uses this to control which players can join each freq and play.

Usage:
select * from league.start_game(23, false);
select * from league.start_game(999999999, false); -- test 404
--select * from league.season_game;
--update league.season_game set game_status_id = 1 where season_game_id = 23
*/

begin
	update league.season_game as sg
	set game_status_id = 2 -- in progress
	where sg.season_game_id = p_season_game_id
		and exists(
			select *
			from league.season as s
			where s.season_id = sg.season_id
				and s.start_date is not null -- season is started
				and s.end_date is null -- season has not ended
		)
		and(sg.game_status_id = 1 -- pending
			or (sg.game_status_id = 2 -- in progress
				and p_force = true
			)
		);

	if FOUND then
		return query
			select 
				 200 as code -- success
				,league.get_season_game_start_info(p_season_game_id) as game_json;
	elsif not exists(select * from league.season_game where season_game_id = p_season_game_id) then
		return query
			select 
				 404 as code -- not found (invalid p_season_game_id)
				,null::json as teams_json;
	else
		return query
			select 
				 409 as code -- failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state and/or p_force not being true)
				,null::json as teams_json;
	end if;
end;

$$;

alter function league.start_game owner to ss_developer;

revoke all on function league.start_game from public;

grant execute on function league.start_game to ss_zone_server;
