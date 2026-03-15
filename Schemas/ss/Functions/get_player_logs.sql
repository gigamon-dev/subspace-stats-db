create or replace function ss.get_player_logs(
	 p_player_name ss.player.player_name%type
	,p_filter_player_log_type_id bigint[]
	,p_filter_league_id league.league.league_id%type
)
returns table(
	 player_log_id ss.player_log.player_log_id%type
	,player_log_type_id ss.player_log.player_log_type_id%type
	,log_timestamp ss.player_log.log_timestamp%type
	,by_player_name ss.player.player_name%type
	,by_user_id ss.player_log.by_user_id%type
	,notes ss.player_log.notes%type
	,league_id league.league.league_id%type
	,league_name league.league.league_name%type
	,league_role_id league.league_role.league_role_id%type
	,league_role_name league.league_role.league_role_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets logs for a specified player.

Usage:
select * from ss.get_player_logs('asdf', null, null);
select * from ss.get_player_logs('asdf', '{1000,1001,1002}', null);
select * from ss.get_player_logs('asdf', null, 13);
select * from ss.get_player_logs('asdf', '{1000,1001,1002}', 13);
*/

select
	 pl.player_log_id
	,pl.player_log_type_id
	,pl.log_timestamp
	,(	select p2.player_name
		from ss.player as p2
		where p2.player_id = pl.by_player_id
	 ) as by_player_name
	,pl.by_user_id
	,pl.notes
	,lpl.league_id
	,l.league_name
	,lprl.league_role_id
	,lr.league_role_name
from ss.player as p
inner join ss.player_log as pl
	on p.player_id = pl.player_id
left outer join league.league_player_log as lpl
	on pl.player_log_id = lpl.player_log_id
left outer join league.league as l
	on lpl.league_id = l.league_id
left outer join league.league_player_role_log as lprl
	on pl.player_log_id = lprl.player_log_id
left outer join league.league_role as lr
	on lprl.league_role_id = lr.league_role_id
where p.player_name = p_player_name
	and (p_filter_player_log_type_id is null or pl.player_log_type_id = any(p_filter_player_log_type_id))
	and (p_filter_league_id is null or lpl.league_id = p_filter_league_id)
order by pl.log_timestamp desc;

$$;

alter function ss.get_player_logs owner to ss_developer;

revoke all on function ss.get_player_logs from public;

grant execute on function ss.get_player_logs to ss_web_server;
