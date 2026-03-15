create or replace function league.insert_league_permit_request(
	 p_player_name ss.player.player_name%type
	,p_league_id league.league.league_id%type
	,p_by_player_name ss.player.player_name%type
	,out league_player_role_request_id league.league_player_role_request.league_player_role_request_id%type
	,out error_message text
)
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Requests a 'Practice Permit' for a specified league.

Parmeters:
p_player_name - The name of the player a permit is being requested for.
p_league_id - The league the permit is being requested for.
p_by_player_name - The name of the player submitting the request. NULL when requesting for oneself.

Returns:
	league_player_role_request_id - Id of a new or existing request. Can be NULL if there is an error_message.
	error_message - An error message. NULL means success.

Usage:
select league.insert_league_permit_request('foo', 13, null);

Verify with:
select * from ss.player where player_name = 'foo';
select * from league.league_player_role_request where player_id = 88;
*/

declare
	l_league_role_id constant league.league_role.league_role_id%type := 2; -- Practice Permit
	l_player_id ss.player.player_id%type;
	l_by_player_id ss.player.player_id%type;
	l_player_log_id ss.player_log.player_log_id%type;
begin
	if not exists(select * from league.league where league_id = p_league_id)
	then
		error_message := 'Invalid league specified.';
		return;
	end if;

	if not exists(
		select * 
		from league.league_role 
		where league_role_id = l_league_role_id
	)
	then
		error_message := 'Invalid role specified.';
		return;
	end if;

	l_player_id := ss.get_or_insert_player(p_player_name);

	if p_by_player_name is not null
	then
		l_by_player_id := ss.get_or_insert_player(p_by_player_name);
	else
		l_by_player_id := l_player_id;
	end if;

	if exists(
		select * 
		from league.league_player_role as lpr
		where lpr.player_id = l_player_id
			and lpr.league_id = p_league_id
			and lpr.league_role_id = l_league_role_id
	)
	then
		error_message := 'A permit has already been granted.';
		return;
	end if;

	if exists(
		select *
		from ss.player_log as pl
		inner join league.league_player_log as lpl
			on pl.player_log_id = lpl.player_log_id
		inner join league.league_player_role_log as lprl
			on pl.player_log_id = lprl.player_log_id
		where pl.player_id = l_player_id
			and pl.player_log_type_id = 1001 -- League - Revoke Role
			and lpl.league_id = p_league_id
			and lprl.league_role_id = l_league_role_id
	)
	then
		error_message := 'A permit cannot be requested since one was previously denied. Follow up with a league manager if you think you think this was done in error.';
		return;
	end if;

	insert into league.league_player_role_request(
		 player_id
		,league_id
		,league_role_id
	)
	values(
		 l_player_id
		,p_league_id
		,l_league_role_id
	)
	on conflict (player_id, league_id, league_role_id) do nothing
	returning league.league_player_role_request.league_player_role_request_id
	into league_player_role_request_id;

	if league_player_role_request_id is null
	then
		select r.league_player_role_request_id
		from league.league_player_role_request as r
		where r.player_id = l_player_id
			and r.league_id = p_league_id
			and r.league_role_id = l_league_role_id
		into league_player_role_request_id;
	
		error_message := 'A permit request has already been submitted.';
		return;
	end if;

	--
	-- insert log records
	--

	insert into ss.player_log(
		 player_id
		,player_log_type_id
		,by_player_id
	)
	values(
		  l_player_id
		 ,1002 -- League - Request Role
		 ,l_by_player_id
	)
	returning player_log_id
	into l_player_log_id;

	insert into league.league_player_log(
		 player_log_id
		,league_id
	)
	values(
		 l_player_log_id
		,p_league_id
	);

	insert into league.league_player_role_log(
		 player_log_id
		,league_role_id
	)
	values(
		 l_player_log_id
		,l_league_role_id
	);
	
	return;
end;

$$;

alter function league.insert_league_permit_request owner to ss_developer;

revoke all on function league.insert_league_permit_request from public;

grant execute on function league.insert_league_permit_request to ss_zone_server;
