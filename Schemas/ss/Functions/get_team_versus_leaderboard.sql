create or replace function ss.get_team_versus_leaderboard(
	 p_stat_period_id ss.stat_period.stat_period_id%type
	,p_limit integer
	,p_offset integer
)
returns table(
	 rating_rank bigint
	,player_name ss.player.player_name%type
	,squad_name ss.squad.squad_name%type
	,rating ss.player_rating.rating%type
	,rating_avg ss.player_versus_stats.rating_avg%type
	,games_played ss.player_versus_stats.games_played%type
	,play_duration ss.player_versus_stats.play_duration%type
	,wins ss.player_versus_stats.wins%type
	,losses ss.player_versus_stats.losses%type
	,kills ss.player_versus_stats.kills%type
	,deaths ss.player_versus_stats.deaths%type
	,damage_dealt bigint
	,damage_taken bigint
	,kill_damage ss.player_versus_stats.kill_damage%type
	,forced_reps ss.player_versus_stats.forced_reps%type
	,forced_rep_damage ss.player_versus_stats.forced_rep_damage%type
	,assists ss.player_versus_stats.assists%type
	,wasted_energy ss.player_versus_stats.wasted_energy%type
	,first_out bigint
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the leaderboard for a team versus stat period.

Parameters:
p_stat_period_id - Id of the stat period to get the leaderboard for. This identifies both the game type and period range.
p_limit - The maximum # of records to return (for pagination).
p_offset - The offset of the records to return (for pagination).

Usage:
select * from ss.get_team_versus_leaderboard(17, 100, 0); -- 2v2pub, monthly
select * from ss.get_team_versus_leaderboard(17, 2, 2); -- 2v2pub, monthly

select * from ss.player_versus_stats;
select * from ss.stat_period;
select * from ss.stat_tracking;
select * from ss.game_type;
*/

select
	 dense_rank() over(order by pr.rating desc) as rating_rank
	,p.player_name
	,s.squad_name
	,pr.rating
	,pvs.rating_avg
	,pvs.games_played
	,pvs.play_duration
	,pvs.wins
	,pvs.losses
	,pvs.kills
	,pvs.deaths
	,pvs.gun_damage_dealt + pvs.bomb_damage_dealt as damage_dealt
	,pvs.gun_damage_taken + pvs.bomb_damage_taken + pvs.team_damage_taken + pvs.self_damage as damage_taken
	,pvs.kill_damage
	,pvs.forced_reps
	,pvs.forced_rep_damage
	,pvs.assists
	,pvs.wasted_energy
	,pvs.first_out_regular as first_out
from ss.player_versus_stats as pvs
inner join ss.player as p
	on pvs.player_id = p.player_id
left outer join ss.squad as s
	on p.squad_id = s.squad_id
left outer join ss.player_rating as pr
	on pvs.player_id = pr.player_id
		and pvs.stat_period_id = pr.stat_period_id
where pvs.stat_period_id = p_stat_period_id
	and p.player_name not like '^%' -- skip unauthenticated players
order by
	 pr.rating desc
	,pvs.play_duration desc
	,pvs.games_played desc
	,pvs.wins desc
	,p.player_name
limit p_limit offset p_offset;

$$;

alter function ss.get_team_versus_leaderboard owner to ss_developer;

revoke all on function ss.get_team_versus_leaderboard from public;

grant execute on function ss.get_team_versus_leaderboard to ss_web_server;
