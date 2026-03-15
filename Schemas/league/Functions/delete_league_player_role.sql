create or replace function league.delete_league_player_role(
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
For a specified league, removes a player's role and/or declines a role request.

Usage:
select league.delete_league_player_role(13, 'bar', 1);
*/

with player_cte as(
	-- Only for existing players
	-- Purposely not calling ss.get_or_insert_player since we don't want to insert a new player
	select player_id
	from ss.player
	where player_name = p_player_name
)
,delete_league_player_role_cte as(
	-- Remove role
	delete from league.league_player_role
	where player_id = (
			select player_id
			from player_cte
		)
		and league_id = p_league_id
		and league_role_id = p_league_role_id
	returning player_id
)
,delete_league_player_role_request_cte as(
	-- Remove pending role request
	delete from league.league_player_role_request as lprr
	where lprr.player_id = (
			select player_id
			from player_cte
		)
		and lprr.league_id = p_league_id
		and lprr.league_role_id = p_league_role_id
	returning player_id
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
		 dt.player_id
		,1001 -- League - Revoke Role
		,case when p_by_player_name is not null
			then ss.get_or_insert_player(p_by_player_name)
			else null 
		 end
		,p_by_user_id
		,p_notes
	from(
		-- only if the role was removed or role request declined
		select player_id
		from delete_league_player_role_cte
		union
		select player_id
		from delete_league_player_role_request_cte
	)  as dt
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
,upsert_league_player_role_status as(
	insert into league.league_player_role_status(
		 league_id
		,league_role_id
		,last_updated
	)
	select
		 p_league_id
		,p_league_role_id
		,current_timestamp
	from delete_league_player_role_cte as dc -- only upsert if the role was removed
	on conflict(league_id, league_role_id)
	do update
	set last_updated = current_timestamp
)
select
	case when( exists(select * from delete_league_player_role_cte)
			or exists(select * from delete_league_player_role_request_cte)
		)
		then TRUE
		else FALSE
	end;
$$;

alter function league.delete_league_player_role owner to ss_developer;

revoke all on function league.delete_league_player_role from public;

grant execute on function league.delete_league_player_role to ss_web_server;
grant execute on function league.delete_league_player_role to ss_zone_server;
