create or replace function ss.get_player_versus_period_stats(
	 p_player_name ss.player.player_name%type
	,p_stat_period_ids bigint[]
)
returns table(
	 stat_period_id ss.stat_period.stat_period_id%type
	,period_rank integer
	,rating ss.player_rating.rating%type
	,games_played ss.player_versus_stats.games_played%type
	,play_duration ss.player_versus_stats.play_duration%type
	,wins ss.player_versus_stats.wins%type
	,losses ss.player_versus_stats.losses%type
	,lag_outs ss.player_versus_stats.lag_outs%type
	,kills ss.player_versus_stats.kills%type
	,deaths ss.player_versus_stats.deaths%type
	,knockouts ss.player_versus_stats.knockouts%type
	,team_kills ss.player_versus_stats.team_kills%type
	,solo_kills ss.player_versus_stats.solo_kills%type
	,assists ss.player_versus_stats.assists%type
	,forced_reps ss.player_versus_stats.forced_reps%type
	,gun_damage_dealt ss.player_versus_stats.gun_damage_dealt%type
	,bomb_damage_dealt ss.player_versus_stats.bomb_damage_dealt%type
	,team_damage_dealt ss.player_versus_stats.team_damage_dealt%type
	,gun_damage_taken ss.player_versus_stats.gun_damage_taken%type
	,bomb_damage_taken ss.player_versus_stats.bomb_damage_taken%type
	,team_damage_taken ss.player_versus_stats.team_damage_taken%type
	,self_damage ss.player_versus_stats.self_damage%type
	,kill_damage ss.player_versus_stats.kill_damage%type
	,team_kill_damage ss.player_versus_stats.team_kill_damage%type
	,forced_rep_damage ss.player_versus_stats.forced_rep_damage%type
	,bullet_fire_count ss.player_versus_stats.bullet_fire_count%type
	,bomb_fire_count ss.player_versus_stats.bomb_fire_count%type
	,mine_fire_count ss.player_versus_stats.mine_fire_count%type
	,bullet_hit_count ss.player_versus_stats.bullet_hit_count%type
	,bomb_hit_count ss.player_versus_stats.bomb_hit_count%type
	,mine_hit_count ss.player_versus_stats.mine_hit_count%type
	,first_out_regular ss.player_versus_stats.first_out_regular%type
	,first_out_critical ss.player_versus_stats.first_out_critical%type
	,wasted_energy ss.player_versus_stats.wasted_energy%type
	,wasted_repel ss.player_versus_stats.wasted_repel%type
	,wasted_rocket ss.player_versus_stats.wasted_rocket%type
	,wasted_thor ss.player_versus_stats.wasted_thor%type
	,wasted_burst ss.player_versus_stats.wasted_burst%type
	,wasted_decoy ss.player_versus_stats.wasted_decoy%type
	,wasted_portal ss.player_versus_stats.wasted_portal%type
	,wasted_brick ss.player_versus_stats.wasted_brick%type
	,enemy_distance_sum ss.player_versus_stats.enemy_distance_sum%type
	,enemy_distance_samples ss.player_versus_stats.enemy_distance_samples%type
	,team_distance_sum ss.player_versus_stats.team_distance_sum%type
	,team_distance_samples ss.player_versus_stats.team_distance_samples%type
	,rating_avg ss.player_versus_stats.rating_avg%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets a player's team versus stats for a specified set of stat periods.

Parameters:
p_player_name - The name of player to get stats for.
p_stat_period_ids - The stat periods to get data for.

Usage:
select * from ss.get_player_versus_period_stats('foo', '{17,3}');
*/

select
	 pvs.stat_period_id
	,(	select dt.rating_rank
		from(
			select
				 dense_rank() over(order by pr.rating desc)::integer as rating_rank
				,pr.player_id
			from ss.player_rating as pr
			where pr.stat_period_id = pvs.stat_period_id
		) as dt
		where dt.player_id = pvs.player_id
	 ) as period_rank
	,pr.rating
	,pvs.games_played
	,pvs.play_duration
	,pvs.wins
	,pvs.losses
	,pvs.lag_outs
	,pvs.kills
	,pvs.deaths
	,pvs.knockouts
	,pvs.team_kills
	,pvs.solo_kills
	,pvs.assists
	,pvs.forced_reps
	,pvs.gun_damage_dealt
	,pvs.bomb_damage_dealt
	,pvs.team_damage_dealt
	,pvs.gun_damage_taken
	,pvs.bomb_damage_taken
	,pvs.team_damage_taken
	,pvs.self_damage
	,pvs.kill_damage
	,pvs.team_kill_damage
	,pvs.forced_rep_damage
	,pvs.bullet_fire_count
	,pvs.bomb_fire_count
	,pvs.mine_fire_count
	,pvs.bullet_hit_count
	,pvs.bomb_hit_count
	,pvs.mine_hit_count
	,pvs.first_out_regular
	,pvs.first_out_critical
	,pvs.wasted_energy
	,pvs.wasted_repel
	,pvs.wasted_rocket
	,pvs.wasted_thor
	,pvs.wasted_burst
	,pvs.wasted_decoy
	,pvs.wasted_portal
	,pvs.wasted_brick
	,pvs.enemy_distance_sum
	,pvs.enemy_distance_samples
	,pvs.team_distance_sum
	,pvs.team_distance_samples
	,pvs.rating_avg
from(
	select p.player_id
	from ss.player as p
	where p.player_name = p_player_name
) as dt
cross join unnest(p_stat_period_ids) with ordinality as pspi(stat_period_id, ordinality)
inner join ss.player_versus_stats as pvs
	on dt.player_id = pvs.player_id
		and pspi.stat_period_id = pvs.stat_period_id
left outer join ss.player_rating as pr -- not all stat periods include rating (e.g. forever)
	on pvs.player_id = pr.player_id
		and pvs.stat_period_id = pr.stat_period_id
order by pspi.ordinality;
		
$$;

alter function ss.get_player_versus_period_stats owner to ss_developer;

revoke all on function ss.get_player_versus_period_stats from public;

grant execute on function ss.get_player_versus_period_stats to ss_web_server;
