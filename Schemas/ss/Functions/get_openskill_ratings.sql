create or replace function ss.get_openskill_ratings(
	 p_game_type_id ss.game_type.game_type_id%type
	,p_player_names character varying(20)[]
)
returns table(
	 player_name ss.player.player_name%type
	,mu ss.player_mmr.mu%type
	,sigma ss.player_mmr.sigma%type
	,last_updated ss.player_mmr.last_updated%type
)
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Gets the OpenSkill rating (mu and sigma) of a specified list of players.
Also, the timestamp that each player last played is included, so that decay for inactivity can be calculated.

Parameters:
p_game_type_id - The type of game to get ratings for.
p_player_names - The names of the players to get data for.

Usage:
select * from ss.get_openskill_ratings(2, '{"foo", "bar", "baz", "asdf"}');
*/

select
	 t.player_name
	,pm.mu
	,pm.sigma
	,pm.last_updated
from unnest(p_player_names) as t(player_name)
inner join ss.player as p
	on t.player_name = p.player_name
inner join ss.player_mmr as pm
	on p.player_id = pm.player_id
where pm.game_type_id = p_game_type_id;

$$;

alter function ss.get_openskill_ratings owner to ss_developer;

revoke all on function ss.get_openskill_ratings from public;

grant execute on function ss.get_openskill_ratings to ss_zone_server;
