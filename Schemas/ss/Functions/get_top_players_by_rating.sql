create or replace function ss.get_top_players_by_rating(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_top integer
)
returns table(
	 top_rank integer
	,player_name ss.player.player_name%type
	,rating ss.player_rating.rating%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the top players by rating for a specified stat period.

Parameters:
p_stat_period_id - Id of the stat period to get data for.
p_top - The rank limit results. 
	E.g. specify 5 to get players with rank [1 - 5].
	This is not the limit of the # of players to return.
	If multiple players share the same rank, they will all be returned.

Usage:
select * from ss.get_top_players_by_rating(16, 5);
*/

select
	 dt.top_rank
	,dt.player_name
	,dt.rating
from(
	select
		 dense_rank() over(order by pr.rating desc)::integer as top_rank
		,p.player_name
		,pr.rating
	from ss.player_rating as pr
	inner join ss.player as p
		on pr.player_id = p.player_id
	where pr.stat_period_id = p_stat_period_id
		and p.player_name not like '^%' -- skip unauthenticated players
) as dt
where dt.top_rank <= p_top
order by
	 dt.top_rank
	,dt.player_name;

$$;

alter function ss.get_top_players_by_rating owner to ss_developer;

revoke all on function ss.get_top_players_by_rating from public;

grant execute on function ss.get_top_players_by_rating to ss_web_server;
