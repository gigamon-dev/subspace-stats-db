create or replace function league.get_league_player_roles(
	 p_league_id league.league.league_id%type
	,p_filter_league_role_id bigint[]
)
returns table(
	 player_name ss.player.player_name%type
	,league_role_id league.league_player_role.league_role_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets player roles for a specified league.

Parameters:
p_league_id - Id of the league to get data for.
p_filter_league_role_id - league_role_ids to filter by. NULL means do not filter.

Usage:
select * from league.get_league_player_roles(13, null); -- no filter)
select * from league.get_league_player_roles(13, '{1}'); -- filter by Practice Permit
*/

select
	 p.player_name
	,lpr.league_role_id
from league.league_player_role as lpr
inner join ss.player as p
	on lpr.player_id = p.player_id
where lpr.league_id = p_league_id
	and (p_filter_league_role_id is null or lpr.league_role_id = any(p_filter_league_role_id))
order by
	 p.player_name
	,lpr.league_role_id;

$$;

alter function league.get_league_player_roles owner to ss_developer;

revoke all on function league.get_league_player_roles from public;

grant execute on function league.get_league_player_roles to ss_web_server;