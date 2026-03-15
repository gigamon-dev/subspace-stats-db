create or replace function league.get_league_player_role_last_updated(
	 p_league_id league.league.league_id%type
	,p_league_role_id league.league_role.league_role_id%type
)
returns league.league_player_role_status.last_updated%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the last updated timestamp for a league_id + player_role_id combination.
This is used to determine whether data has changed since it was last retrieved.

Usage:
select league.get_league_player_role_last_updated(13, 2);
*/

select lprs.last_updated
from league.league_player_role_status as lprs
where lprs.league_id = p_league_id
	and lprs.league_role_id = p_league_role_id;

$$;

alter function league.get_league_player_role_last_updated owner to ss_developer;

revoke all on function league.get_league_player_role_last_updated from public;

grant execute on function league.get_league_player_role_last_updated to ss_zone_server;
