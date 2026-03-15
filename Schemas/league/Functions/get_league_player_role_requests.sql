create or replace function league.get_league_player_role_requests(
	 p_league_id league.league.league_id%type
	,p_filter_league_role_id bigint[]
)
returns table(
	 player_name ss.player.player_name%type
	,league_role_id league.league_player_role_request.league_role_id%type
	,request_timestamp league.league_player_role_request.request_timestamp%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets pending league role requests.

Parameters:
p_league_id - The league to get data for.
p_filter_league_role_id - The league_role_ids to filter by. NULL means no filter.

Usage:
select * from league.get_league_player_role_requests(13, null);
select * from league.get_league_player_role_requests(13, '{2}');
*/

select
	 p.player_name
	,r.league_role_id
	,r.request_timestamp
from league.league_player_role_request as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.league_id = p_league_id
	and (p_filter_league_role_id is null or r.league_role_id = any(p_filter_league_role_id))
order by request_timestamp asc;

$$;

alter function league.get_league_player_role_requests owner to ss_developer;

revoke all on function league.get_league_player_role_requests from public;

grant execute on function league.get_league_player_role_requests to ss_web_server;
grant execute on function league.get_league_player_role_requests to ss_zone_server;
