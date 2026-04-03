create or replace function ss.get_top_versus_players_by_avg_rating(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_top integer
	,p_min_games_played integer = 1
)
returns table(
	 top_rank bigint
	,player_name ss.player.player_name%type
	,avg_rating real
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the top players by average rating for a specified stat period.

Parameters:
p_stat_period_id - Id of the stat period to get data for.
p_top - The rank limit results. 
	E.g. specify 5 to get players with rank [1 - 5].
	This is not the limit of the # of players to return.
	If multiple players share the same rank, they will all be returned.
p_min_games_played - The minimum # of games a player must have played to be included in the result.

Usage:
select * from ss.get_top_versus_players_by_avg_rating(17, 5, 3);
select * from ss.get_top_versus_players_by_avg_rating(17, 5);
*/

declare
	l_initial_rating ss.stat_tracking.initial_rating%type;
begin
	if p_min_games_played < 1 then
		p_min_games_played := 1;
	end if;

	select st.initial_rating
	into l_initial_rating
	from ss.stat_period as sp
	inner join ss.stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where sp.stat_period_id = p_stat_period_id;

	if l_initial_rating is null then
		raise exception 'Invalid stat period specified. (%)', p_stat_period_id;
	end if;

	return query
		select
			 dt2.top_rank
			,dt2.player_name
			,dt2.avg_rating
		from(
			select
				 dense_rank() over(order by dt.avg_rating desc) as top_rank
				,dt.player_name
				,dt.avg_rating
			from(
				select
					 p.player_name
					,(pr.rating - l_initial_rating)::real / pvs.games_played::real as avg_rating
				from ss.player_rating as pr
				inner join ss.player as p
					on pr.player_id = p.player_id
				inner join ss.player_versus_stats as pvs
					on pr.player_id = pvs.player_id
						and pr.stat_period_id = pvs.stat_period_id
				where pr.stat_period_id = p_stat_period_id
					and p.player_name not like '^%' -- skip unauthenticated players
					and pvs.games_played >= coalesce(p_min_games_played, 1)
			) as dt
		) as dt2
		where dt2.top_rank <= p_top
		order by
			 dt2.top_rank
			,dt2.player_name;
end;
$$;

alter function ss.get_top_versus_players_by_avg_rating owner to ss_developer;

revoke all on function ss.get_top_versus_players_by_avg_rating from public;

grant execute on function ss.get_top_versus_players_by_avg_rating to ss_web_server;
