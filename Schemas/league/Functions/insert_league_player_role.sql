create or replace function league.insert_league_player_role(
	 p_player_name ss.player.player_name%type
	,p_league_id league.league.league_id%type
	,p_league_role_id league.league_player_role.league_role_id%type
	,p_by_player_name ss.player.player_name%type
	,p_by_user_id ss.player_log.by_user_id%type
	,p_notes ss.player_log.notes%type
)
returns boolean
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Inserts a record into the league.league_player_role table.

Parameters:
p_player_name - The player to assign the role to.
p_league_id - The league to assign the role for.
p_league_role_id - The role to assign.
p_by_player_name - [optional] The player who is assigning the role. 
p_by_user_id - [optional] The user who is assigning the role.
p_notes - [optional] Notes / comments to save into the log.

Returns:
	TRUE if the player role was inserted. FALSE if the player role already existed.

Usage:
select league.insert_league_player_role('asdf', 13, 2, 'foo', null, 'testing');
*/

with insert_league_player_role_cte as(
	insert into league.league_player_role(
		 player_id
		,league_id
		,league_role_id
	)
	select
		 dt.player_id
		,p_league_id
		,p_league_role_id
	from(
		select ss.get_or_insert_player(p_player_name) as player_id
	) as dt
	where not exists(
			select * 
			from league.league_player_role as lpr
			where lpr.player_id = dt.player_id
				and lpr.league_id = p_league_id
				and lpr.league_role_id = p_league_role_id
		)
	returning
		 player_id
)
,delete_league_player_role_request_cte as(
	-- Remove pending role requests
	delete from league.league_player_role_request as lprr
	where lprr.player_id = (
			select player_id
			from insert_league_player_role_cte
		)
		and lprr.league_id = p_league_id
		and lprr.league_role_id = p_league_role_id
)
,insert_player_log_cte as(
	insert into ss.player_log(
		 player_id
		,player_log_type_id
		,by_player_id
		,by_user_id
		,notes
	)
	select
		 c.player_id
		,1000 -- League - Grant Role
		,case when p_by_player_name is not null
			then ss.get_or_insert_player(p_by_player_name)
			else null 
		 end
		,p_by_user_id
		,p_notes
	from insert_league_player_role_cte as c
	returning
		player_log_id
)
,insert_league_player_log_cte as(
	insert into league.league_player_log(
		 player_log_id
		,league_id
	)
	select
		 c.player_log_id
		,p_league_id
	from insert_player_log_cte as c
)
,insert_league_player_role_log_cte as(
	insert into league.league_player_role_log(
		 player_log_id
		,league_role_id
	)
	select
		 c.player_log_id
		,p_league_role_id
	from insert_player_log_cte as c
)
,insert_league_player_role_status_cte as(
	insert into league.league_player_role_status(
		 league_id
		,league_role_id
		,last_updated
	)
	select
		 p_league_id
		,p_league_role_id
		,current_timestamp
	from insert_league_player_role_cte
	on conflict(league_id, league_role_id)
	do update
	set last_updated = current_timestamp
)
select 
	case when exists(select * from insert_league_player_role_cte)
		then TRUE
		else FALSE
	end;

$$;

alter function league.insert_league_player_role owner to ss_developer;

revoke all on function league.insert_league_player_role from public;

grant execute on function league.insert_league_player_role to ss_web_server;
grant execute on function league.insert_league_player_role to ss_zone_server;
