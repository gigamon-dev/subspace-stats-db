-- This script upgrades v2.0.0 to v2.1.0

insert into migration.db_change_log(
	 applied_timestamp
	,major
	,minor
	,patch
	,script_file_name
)
values(
	 CURRENT_TIMESTAMP
	,2
	,1
	,0
	,'v2.1.0-league.sql'
);

-- Schemas/ss/Tables/stat_period.sql
-- The ss.stat_period table had a unique constraint on (stat_tracking_id, period_range).
-- This made sense for regular periods (Monthly, Forever) where there would be one period per month for the game type being tracked.
-- However, it doesn't work for League Season periods. There could be multiple seasons for the same game type with the same period.
-- This normally would be very unlikely. However, it is possible. 
--
-- Also, there's a scenario where it's likely to occur unintentionally:
-- 1. Create a season
-- 2. Start the season (which creates the stat period)
-- 3. Delete the season (the stat period is not deleted)
-- 4. Create and start another season with the same start date, but the constraint will conflict.
ALTER TABLE IF EXISTS ss.stat_period DROP CONSTRAINT IF EXISTS stat_period_stat_tracking_id_period_range_key;

--
-- Schemas/ss/Tables/player_log_type.sql
--

-- Table: ss.player_log_type

-- DROP TABLE IF EXISTS ss.player_log_type;

CREATE TABLE IF NOT EXISTS ss.player_log_type
(
    player_log_type_id bigint NOT NULL,
    player_log_type_description text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT player_log_type_pkey PRIMARY KEY (player_log_type_id),
    CONSTRAINT player_log_type_player_log_type_description_key UNIQUE (player_log_type_description)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_log_type
    OWNER to ss_developer;

--
-- Schemas/ss/Tables/player_log.sql
--

-- Table: ss.player_log

-- DROP TABLE IF EXISTS ss.player_log;

CREATE TABLE IF NOT EXISTS ss.player_log
(
    player_log_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    player_id bigint NOT NULL,
    player_log_type_id bigint NOT NULL,
    log_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    by_player_id bigint,
    by_user_id text COLLATE pg_catalog."default",
    notes text COLLATE pg_catalog."default",
    CONSTRAINT player_log_pkey PRIMARY KEY (player_log_id),
    CONSTRAINT player_log_by_player_id_fkey FOREIGN KEY (by_player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_log_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_log_player_log_type_id_fkey FOREIGN KEY (player_log_type_id)
        REFERENCES ss.player_log_type (player_log_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_log
    OWNER to ss_developer;

--
-- Schemas/league/Tables/league_player_log.sql
--

-- Table: league.league_player_log

-- DROP TABLE IF EXISTS league.league_player_log;

CREATE TABLE IF NOT EXISTS league.league_player_log
(
    player_log_id bigint NOT NULL,
    league_id bigint NOT NULL,
    CONSTRAINT league_player_log_pkey PRIMARY KEY (player_log_id),
    CONSTRAINT league_player_log_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_player_log_player_log_id_fkey FOREIGN KEY (player_log_id)
        REFERENCES ss.player_log (player_log_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_player_log
    OWNER to ss_developer;

--
-- Schemas/league/Tables/league_player_role.sql
--

-- Table: league.league_player_role

-- DROP TABLE IF EXISTS league.league_player_role;

CREATE TABLE IF NOT EXISTS league.league_player_role
(
    player_id bigint NOT NULL,
    league_id bigint NOT NULL,
    league_role_id bigint NOT NULL,
    CONSTRAINT league_player_role_pkey PRIMARY KEY (player_id, league_id, league_role_id),
    CONSTRAINT league_player_role_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_player_role_league_role_id_fkey FOREIGN KEY (league_role_id)
        REFERENCES league.league_role (league_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_player_role_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_player_role
    OWNER to ss_developer;
-- Index: league_player_role_league_id_player_id_league_role_id_idx

-- DROP INDEX IF EXISTS league.league_player_role_league_id_player_id_league_role_id_idx;

CREATE INDEX IF NOT EXISTS league_player_role_league_id_player_id_league_role_id_idx
    ON league.league_player_role USING btree
    (league_id ASC NULLS LAST)
    INCLUDE(player_id, league_role_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;

--
-- Schemas/league/Tables/league_player_role_log.sql
--

-- Table: league.league_player_role_log

-- DROP TABLE IF EXISTS league.league_player_role_log;

CREATE TABLE IF NOT EXISTS league.league_player_role_log
(
    player_log_id bigint NOT NULL,
    league_role_id bigint NOT NULL,
    CONSTRAINT league_player_role_log_pkey PRIMARY KEY (player_log_id),
    CONSTRAINT league_player_role_log_league_role_id_fkey FOREIGN KEY (league_role_id)
        REFERENCES league.league_role (league_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_player_role_log_player_log_id_fkey FOREIGN KEY (player_log_id)
        REFERENCES ss.player_log (player_log_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_player_role_log
    OWNER to ss_developer;

--
-- Schemas/league/Tables/league_player_role_request.sql
--

-- Table: league.league_player_role_request

-- DROP TABLE IF EXISTS league.league_player_role_request;

CREATE TABLE IF NOT EXISTS league.league_player_role_request
(
    league_player_role_request_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    player_id bigint NOT NULL,
    league_id bigint NOT NULL,
    league_role_id bigint NOT NULL,
    request_timestamp timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT league_player_role_request_pkey PRIMARY KEY (league_player_role_request_id),
    CONSTRAINT league_player_role_request_player_id_league_id_player_role__key UNIQUE (player_id, league_id, league_role_id),
    CONSTRAINT league_player_role_request_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_player_role_request_league_role_id_fkey FOREIGN KEY (league_role_id)
        REFERENCES league.league_role (league_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT league_player_role_request_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_player_role_request
    OWNER to ss_developer;
-- Index: league_player_role_request_league_id_request_timestamp_idx

-- DROP INDEX IF EXISTS league.league_player_role_request_league_id_request_timestamp_idx;

CREATE INDEX IF NOT EXISTS league_player_role_request_league_id_request_timestamp_idx
    ON league.league_player_role_request USING btree
    (league_id ASC NULLS LAST, request_timestamp ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;

--
-- Schemas/league/Tables/league_player_role_status.sql
--

-- Table: league.league_player_role_status

-- DROP TABLE IF EXISTS league.league_player_role_status;

CREATE TABLE IF NOT EXISTS league.league_player_role_status
(
    league_id bigint NOT NULL,
    league_role_id bigint NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    CONSTRAINT league_player_role_status_pkey PRIMARY KEY (league_id, league_role_id),
    CONSTRAINT league_player_role_status_league_id_fkey FOREIGN KEY (league_id)
        REFERENCES league.league (league_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT league_player_role_status_league_role_id_fkey FOREIGN KEY (league_role_id)
        REFERENCES league.league_role (league_role_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.league_player_role_status
    OWNER to ss_developer;

--
-- Schemas/ss/Scripts/player_log_type-data.sql
--

merge into ss.player_log_type as t
using(
	values
		--  (1, 'Created')
		-- ,(2, 'Update name')
		-- ,(3, 'Update squad')
		-- ,(4, 'Update resolution')
		 (1000, 'League - Grant Role')
		,(1001, 'League - Revoke Role')
		,(1002, 'League - Request Role')
		-- ,(2000, 'League Season - Signup')
		-- ,(2001, 'League Season - Unsignup')
		-- ,(2100, 'League Season - Add to Team')
		-- ,(2101, 'League Season - Remove from Team')
		-- ,(2103, 'League Season - Suspended')
		-- ,(2104, 'League Season - Unsuspended')
) as v(player_log_type_id, player_log_type_description)
	on t.player_log_type_id = v.player_log_type_id
when matched then
	update set
		 player_log_type_description = v.player_log_type_description
when not matched then
	insert(
		 player_log_type_id
		,player_log_type_description
	)
	values(
		 v.player_log_type_id
		,v.player_log_type_description
	);
	
--
-- Schemas/league/Scripts/league_role-data.sql
--

merge into league.league_role as lr
using(
	values
		 (1, 'Manager')
		,(2, 'Practice Permit')
		,(3, 'Permit Manager')
		--,(4, 'Private Match Captain') -- TODO: perhaps in the future?
) as v(league_role_id, league_role_name)
	on lr.league_role_id = v.league_role_id
when matched and v.league_role_name <> lr.league_role_name then
	update set
		league_role_name = v.league_role_name
when not matched then
	insert(
		 league_role_id
		,league_role_name
	)
	values(
		 v.league_role_id
		,v.league_role_name
	);

--
-- Schemas/ss/Functions/get_player_logs.sql
--

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

--
-- Schemas/league/Functions/get_season_players.sql
--

create or replace function league.get_season_players(
	p_season_id league.season.season_id%type
)
returns table(
	 player_id ss.player.player_id%type
	,player_name ss.player.player_name%type
	,signup_timestamp league.roster.signup_timestamp%type
	,team_id league.roster.team_id%type
	,enroll_timestamp league.roster.enroll_timestamp%type
	,is_captain league.roster.is_captain%type
	,is_suspended league.roster.is_suspended%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Usage:
select * from league.get_season_players(2);
*/

select
	 r.player_id
	,p.player_name
	,r.signup_timestamp
	,r.team_id
	,r.enroll_timestamp
	,r.is_captain
	,r.is_suspended
from league.roster as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.season_id = p_season_id
order by p.player_name;

$$;

alter function league.get_season_players owner to ss_developer;

revoke all on function league.get_season_players from public;

grant execute on function league.get_season_players to ss_web_server;

--
-- Schemas/league/Functions/start_game.sql
--

create or replace function league.start_game(
	 p_season_game_id league.season_game.season_game_id%type
	,p_force boolean
)
returns table(
	 code integer
	,game_json json
)
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Starts a league game.
This is intended to be called by a zone server when announcing a game.
This could happen by an automated process based on league.season_game.game_timestamp, 
or manually by an league referee (perhaps a command like: ?startleaguegame <season game id>).
The return value tells the zone if it should continue or abort.

TODO: If we want to allow captains to start a game, then we'll have to also check the game_timestamp too.

Normally, the game will be in the "Pending" state when this is called.
Alternatively, if the game already is "In Progress", it can be overriden with the p_force parameter.
This might be useful if the game was rescheduled or there was a problem such as the zone server crashing.
The idea is that a league referee could force restart a match (perhaps a command like: ?startleaguegame -f <season game id>).

Parmeters:
p_season_game_id - The season game to start.
p_force - True to force the update (when already "In Progress")

Returns: a single record
code: 
	200 - success 
	404 - not found (invalid p_season_game_id)
	409 - failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state and/or p_force not being true)
(based on http status codes)

game_json:
	When code = 200 (success), json containing information about the game.
	See the league.get_season_game function for details.
	The league game mode logic uses this to control which players can join each freq and play.

Usage:
select * from league.start_game(23, false);
select * from league.start_game(999999999, false); -- test 404
--select * from league.season_game;
--update league.season_game set game_status_id = 1 where season_game_id = 23
*/

begin
	update league.season_game as sg
	set game_status_id = 2 -- in progress
	where sg.season_game_id = p_season_game_id
		and exists(
			select *
			from league.season as s
			where s.season_id = sg.season_id
				and s.start_date is not null -- season is started
				and s.end_date is null -- season has not ended
		)
		and(sg.game_status_id = 1 -- pending
			or (sg.game_status_id = 2 -- in progress
				and p_force = true
			)
		);

	if FOUND then
		return query
			select 
				 200 as code -- success
				,league.get_season_game_start_info(p_season_game_id) as game_json;
	elsif not exists(select * from league.season_game where season_game_id = p_season_game_id) then
		return query
			select 
				 404 as code -- not found (invalid p_season_game_id)
				,null::json as teams_json;
	else
		return query
			select 
				 409 as code -- failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state and/or p_force not being true)
				,null::json as teams_json;
	end if;
end;

$$;

alter function league.start_game owner to ss_developer;

revoke all on function league.start_game from public;

grant execute on function league.start_game to ss_zone_server;

--
-- Schemas/league/Functions/undo_start_game.sq
--

create or replace function league.undo_start_game(
	 p_season_game_id league.season_game.season_game_id%type
)
returns integer
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Undo the start of a league game (change the state from "In Progress" back to "Pending").
This is intended to be called after a game has been announced via league.start_game
and a referee wants to undo it, perhaps because the game should be rescheduled.

Parmeters:
p_season_game_id - The season game to uninitialize.

Returns: 
	200 - success 
	404 - not found (invalid p_season_game_id)
	409 - failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state)
(based on http status codes)

Usage:
select * from league.undo_start_game(23);
select * from league.undo_start_game(999999999); -- test 404
--select * from league.season_game;
--update league.season_game set game_status_id = 1 where season_game_id = 23
select * from league.game_status
*/

begin
	update league.season_game as sg
	set game_status_id = 1 -- pending
	where sg.season_game_id = p_season_game_id
		and exists(
			select *
			from league.season as s
			where s.season_id = sg.season_id
				and s.start_date is not null -- season is started
				and s.end_date is null -- season has not ended
		)
		and sg.game_status_id = 2; -- in progress

	if FOUND then
		return 200; -- success
	elsif not exists(select * from league.season_game where season_game_id = p_season_game_id) then
		return 404; -- not found (invalid p_season_game_id)
	else
		return 409; -- failed (p_season_game_id was valid, but it could not be updated due to being in the wrong state)
	end if;
end;

$$;

alter function league.undo_start_game owner to ss_developer;

revoke all on function league.undo_start_game from public;

grant execute on function league.undo_start_game to ss_zone_server;

--
-- Schemas/league/Functions/end_season.sql
--

create or replace function league.end_season(
	 p_season_id league.season.season_id%type
)
returns void
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Ends a season by setting the season's end date and the associated stat period's the upper bound.
*/

declare
	l_end_timestamp timestamptz;
begin
	l_end_timestamp :=
		coalesce(
			 (
				select max(dt.game_timestamp)
				from(
					select sg.game_timestamp
					from league.season_game as sg
					where sg.season_id = p_season_id
					union 
					select upper(g.time_played)
					from league.season_game as sg2
					inner join ss.game as g
						on sg2.game_id = g.game_id
					where sg2.season_id = p_season_id
				) as dt
			 )
			,current_timestamp
		);
	
	update ss.stat_period as sp
	set period_range = tstzrange(lower(sp.period_range), l_end_timestamp, '[]')
	where sp.stat_period_id = (
			select s.stat_period_id
			from league.season as s
			where s.season_id = p_season_id
		)
		and upper_inf(sp.period_range); -- no upper bound yet (this is expected)
	
	update league.season
	set end_date = l_end_timestamp
	where season_id = p_season_id;
end;
$$;

alter function league.end_season owner to ss_developer;

revoke all on function league.end_season from public;

grant execute on function league.end_season to ss_web_server;

--
-- Schemas/league/Functions/delete_league_player_role.sql
--

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

--
-- Schemas/league/Functions/get_league_player_role_grants.sql
--

create or replace function league.get_league_player_role_grants(
	 p_league_id bigint
	,p_league_role_id bigint
)
returns table(
	player_name ss.player.player_name%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the players that have a specified role for a league.

Usage:
select * from league.get_league_player_role_grants(13, 2);
*/

select p.player_name
from league.league_player_role as lpr
inner join ss.player as p
	on lpr.player_id = p.player_id
where lpr.league_id = p_league_id
	and lpr.league_role_id = p_league_role_id;

$$;

alter function league.get_league_player_role_grants owner to ss_developer;

revoke all on function league.get_league_player_role_grants from public;

grant execute on function league.get_league_player_role_grants to ss_zone_server;

--
-- Schemas/league/Functions/get_league_player_role_last_updated.sql
--

create or replace function league.get_league_player_role_last_updated(
	 p_league_id league.league.league_id%type
	,p_league_role_id league.league_role.league_role_id%type
)
returns league.league_player_role_status.last_updated%type
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets the last updated timestamp for a league_id + player_role_id combination.
This is used to determine whether data has changed since it was last retrieved.

Usage:
select league.get_league_player_role_last_updated(13, 2);
*/

select lprs.last_updated
from league.league_player_role_status as lprs
where lprs.league_id = p_league_id
	and lprs.league_role_id = p_league_role_id;

$$;

alter function league.get_league_player_role_last_updated owner to ss_developer;

revoke all on function league.get_league_player_role_last_updated from public;

grant execute on function league.get_league_player_role_last_updated to ss_zone_server;

--
-- Schemas/league/Functions/get_league_player_role_requests.sql
--

create or replace function league.get_league_player_role_requests(
	 p_league_id league.league.league_id%type
	,p_filter_league_role_id bigint[]
)
returns table(
	 player_name ss.player.player_name%type
	,league_role_id league.league_player_role_request.league_role_id%type
	,request_timestamp league.league_player_role_request.request_timestamp%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets pending league role requests.

Parameters:
p_league_id - The league to get data for.
p_filter_league_role_id - The league_role_ids to filter by. NULL means no filter.

Usage:
select * from league.get_league_player_role_requests(13, null);
select * from league.get_league_player_role_requests(13, '{2}');
*/

select
	 p.player_name
	,r.league_role_id
	,r.request_timestamp
from league.league_player_role_request as r
inner join ss.player as p
	on r.player_id = p.player_id
where r.league_id = p_league_id
	and (p_filter_league_role_id is null or r.league_role_id = any(p_filter_league_role_id))
order by request_timestamp asc;

$$;

alter function league.get_league_player_role_requests owner to ss_developer;

revoke all on function league.get_league_player_role_requests from public;

grant execute on function league.get_league_player_role_requests to ss_web_server;
grant execute on function league.get_league_player_role_requests to ss_zone_server;

--
-- Schemas/league/Functions/get_league_player_roles.sql
--

create or replace function league.get_league_player_roles(
	 p_league_id league.league.league_id%type
	,p_filter_league_role_id bigint[]
)
returns table(
	 player_name ss.player.player_name%type
	,league_role_id league.league_player_role.league_role_id%type
)
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets player roles for a specified league.

Parameters:
p_league_id - Id of the league to get data for.
p_filter_league_role_id - league_role_ids to filter by. NULL means do not filter.

Usage:
select * from league.get_league_player_roles(13, null); -- no filter)
select * from league.get_league_player_roles(13, '{1}'); -- filter by Practice Permit
*/

select
	 p.player_name
	,lpr.league_role_id
from league.league_player_role as lpr
inner join ss.player as p
	on lpr.player_id = p.player_id
where lpr.league_id = p_league_id
	and (p_filter_league_role_id is null or lpr.league_role_id = any(p_filter_league_role_id))
order by
	 p.player_name
	,lpr.league_role_id;

$$;

alter function league.get_league_player_roles owner to ss_developer;

revoke all on function league.get_league_player_roles from public;

grant execute on function league.get_league_player_roles to ss_web_server;

--
-- Schemas/league/Functions/insert_league_permit_request.sql
--

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

--
-- Schemas/league/Functions/insert_league_player_role.sql
--

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

--
-- Schemas/league/Functions/is_user_league_permit_manager.sql
--

create or replace function league.is_user_league_permit_manager(
	 p_user_id text
	,p_league_id league.league.league_id%type
)
returns boolean
language sql
security definer
set search_path = league, pg_temp
as
$$

/*
Gets whether a user is a 'Permit Manager' of a league.
*/

select
	exists(
		select *
		from league.league_user_role
		where user_id = p_user_id
			and league_id = p_league_id
			and league_role_id = 3 -- Permit Manager
	);

$$;

alter function league.is_user_league_permit_manager owner to ss_developer;

revoke all on function league.is_user_league_permit_manager from public;

grant execute on function league.is_user_league_permit_manager to ss_web_server;
