create or replace function ss.get_top_versus_players_by_kills_per_minute(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer = 1
)
returns table(
	 top_rank bigint
	,player_name ss.player.player_name%type
	,kills_per_minute real
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the top players by kills per minute for a specified stat period.

Parameters:
p_stat_period_id - Id of the stat period to get data for.
p_top - The rank limit results. 
	E.g. specify 5 to get players with rank [1 - 5].
	This is not the limit of the # of players to return.
	If multiple players share the same rank, they will all be returned.
p_min_games_played - The minimum # of games a player must have played to be included in the result.

Usage:
select * from ss.get_top_versus_players_by_kills_per_minute(17, 5, 3);
select * from ss.get_top_versus_players_by_kills_per_minute(17, 5);
*/

select
	 dt2.top_rank
	,dt2.player_name
	,dt2.kills_per_minute
from(
	select
		 dense_rank() over(order by dt.kills_per_minute desc) as top_rank
		,dt.player_name
		,dt.kills_per_minute
	from(
		select
			 p.player_name
			,(pvs.kills::real / (extract(epoch from pvs.play_duration) / 60))::real as kills_per_minute
		from ss.player_versus_stats as pvs
		inner join ss.player as p
			on pvs.player_id = p.player_id
		where pvs.stat_period_id = p_stat_period_id
			and pvs.kills > 0 -- has at least one kill
			and pvs.games_played >= greatest(coalesce(p_min_games_played, 1), 1)
			and p.player_name not like '^%' -- skip unauthenticated players
	) as dt
) as dt2
where dt2.top_rank <= p_top
order by
	 dt2.top_rank
	,dt2.player_name;

$$;

alter function ss.get_top_versus_players_by_kills_per_minute owner to ss_developer;

revoke all on function ss.get_top_versus_players_by_kills_per_minute from public;

grant execute on function ss.get_top_versus_players_by_kills_per_minute to ss_web_server;
