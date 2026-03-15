create or replace function league.get_league_player_role_grants(
	 p_league_id bigint
	,p_league_role_id bigint
)
returns table(
	player_name ss.player.player_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the players that have a specified role for a league.

Usage:
select * from league.get_league_player_role_grants(13, 2);
*/

select p.player_name
from league.league_player_role as lpr
inner join ss.player as p
	on lpr.player_id = p.player_id
where lpr.league_id = p_league_id
	and lpr.league_role_id = p_league_role_id;

$$;

alter function league.get_league_player_role_grants owner to ss_developer;

revoke all on function league.get_league_player_role_grants from public;

grant execute on function league.get_league_player_role_grants to ss_zone_server;
