create or replace function ss.get_player_participation_overview(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
)
returns table(
	 stat_period_id stat_period.stat_period_id%type
	,game_type_id game_type.game_type_id%type
	,stat_period_type_id stat_period_type.stat_period_type_id%type
	,period_range stat_period.period_range%type
	,rating player_rating.rating%type
	,details_json json
)
language plpgsql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's recent participation across game types.

Parameters:
p_player_name - The name of the player to get data for.
p_period_cutoff - How far back in time to look for data.

Usage:
select * from get_player_participation_overview('foo', interval '1 year');
*/

declare
	l_start timestamptz;
	l_player_id player.player_id%type;
begin
	l_start := current_timestamp - coalesce(p_period_cutoff, interval '1 year');
	
	select p.player_id
	into l_player_id
	from player as p
	where p.player_name = p_player_name;

	if l_player_id is null then
		raise exception 'Invalid player name specified (%)', p_player_name;
	end if;

	return query
		with cte_stat_periods as( -- TODO: add support for other game types (solo, pb)
			select
				 sp.stat_period_id
				,sp.stat_tracking_id
				,sp.period_range
			from player_versus_stats as pvs
			inner join stat_period as sp
				on pvs.stat_period_id = sp.stat_period_id
			where pvs.player_id = l_player_id
				and lower(sp.period_range) >= l_start
		)
		select
			  dt2.stat_period_id
			 ,st.game_type_id
			 ,st.stat_period_type_id
			 ,sp.period_range
			 ,pr.rating
			 ,case when gt.is_team_versus = true then(
				 	select to_json(dt.*)
				 	from(
						select
							 count(*) as games_played
							,sum(case when vgt.is_winner then 1 else 0 end) as wins
							,sum(
								case when vgt.is_winner = false
									and exists(
										-- another team that won (distinguishes from a draw, no winner)
										select *
										from versus_game_team as vgt2
										where vgt2.game_id = vgt.game_id
											and vgt2.freq <> vgt.freq
											and vgt2.is_winner = true
									)
									then 1
									else 0
								end
							) as losses
						from game as g
						inner join versus_game_team_member as vgtm
							on g.game_id = vgtm.game_id
								and vgtm.player_id = l_player_id
						inner join versus_game_team as vgt
							on g.game_id = vgt.game_id
								and vgtm.freq = vgt.freq
						where sp.period_range @> g.time_played
							and g.game_type_id = st.game_type_id
						group by vgtm.player_id
					) as dt
				)
				when gt.is_solo then(
					select to_json(dt.*)
				 	from(
						select
							 count(*) as games_played
							,sum(case when sgp.is_winner then 1 else 0 end) as wins
						from game as g
						inner join solo_game_participant as sgp
							on g.game_id = sgp.game_id
								and sgp.player_id = l_player_id
						where sp.period_range @> g.time_played
							and g.game_type_id = st.game_type_id
					) as dt
				)
-- 				when gt.is_pb then(
-- 				)
			  end as details_json
		from(
			select
				 dt.stat_tracking_id
				,(	select crp2.stat_period_id
					from cte_stat_periods as crp2
					where crp2.stat_tracking_id = dt.stat_tracking_id
					order by crp2.period_range desc
					limit 1
				 ) as stat_period_id -- the last stat period the player particpated in
			from(
				select csp.stat_tracking_id
				from cte_stat_periods as csp
				group by csp.stat_tracking_id
			) as dt
		) as dt2
		inner join stat_tracking as st
			on dt2.stat_tracking_id = st.stat_tracking_id
		inner join game_type as gt
			on st.game_type_id = gt.game_type_id
		inner join stat_period as sp
			on dt2.stat_period_id = sp.stat_period_id
		left outer join player_rating as pr
			on pr.player_id = l_player_id
				and sp.stat_period_id = pr.stat_period_id
		order by sp.period_range desc;
end;
$$;

revoke all on function ss.get_player_participation_overview(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) from public;

grant execute on function ss.get_player_participation_overview(
	 p_player_name player.player_name%type
	,p_period_cutoff interval
) to ss_web_server;
