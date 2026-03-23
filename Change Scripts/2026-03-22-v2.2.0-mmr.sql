-- This script upgrades v2.1.0 to v2.2.0

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
	,2
	,0
	,'v2.2.0-league.sql'
);

--
-- Schemas/ss/Tables/player_mmr.sql
--

-- Table: ss.player_mmr

-- DROP TABLE IF EXISTS ss.player_mmr;

CREATE TABLE IF NOT EXISTS ss.player_mmr
(
    player_id bigint NOT NULL,
    game_type_id bigint NOT NULL,
    mu double precision NOT NULL,
    sigma double precision NOT NULL,
    last_updated timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT player_mmr_pkey PRIMARY KEY (player_id, game_type_id),
    CONSTRAINT player_mmr_game_type_id_fkey FOREIGN KEY (game_type_id)
        REFERENCES ss.game_type (game_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_mmr_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_mmr
    OWNER to ss_developer;
-- Index: player_mmr_game_type_id_idx

-- DROP INDEX IF EXISTS ss.player_mmr_game_type_id_idx;

CREATE INDEX IF NOT EXISTS player_mmr_game_type_id_idx
    ON ss.player_mmr USING btree
    (game_type_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;

--
-- Schemas/ss/Functions/get_openskill_ratings.sql
--

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

--
-- Schemas/ss/Functions/save_game.sql
--

create or replace function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type = null
)
returns ss.game.game_id%type
language sql
security definer
set search_path = ss, pg_temp
as
$$

/*
Saves data for a completed game into the database.

Parameters:
p_stat_period_id - An optional, stat period that limits which stat periods the game should be saved for.
	For regular games, no period is passed. The game's stats will be applied to all of the stat periods that match the game's game type and game time.
	For league matches, the season's stat period is passed. This is so that if there are multiple active seasons with the same game type, the game's stats
	can be applied to only the season's stat period and lifetime/forever period.

p_game_json - JSON that represents the game data to save.

	The JSON differs based on game_type:
	- "solo_stats" for solo game modes (e.g. 1v1, 1v1v1, FFA 1 player/team, ...)
	- "team_stats" for team game modes (e.g. 2v2, 3v3, 4v4, 2v2v2, FFA, 2 players/team, ...) where each team has a fixed # of slots
	- "pb_stats" for powerball game modes

	"events" - Array of events, such as a player "kill"

Usage (team versus):
select ss.save_game('
{
	"game_type_id" : "4",
	"zone_server_name" : "Test Server",
	"arena" : "4v4pub",
	"box_number" : 1,
	"lvl_file_name" : "teamversus.lvl",
	"lvl_checksum" : 12345,
	"start_timestamp" : "2023-08-16 12:00",
	"end_timestamp" : "2023-08-16 12:30",
	"replay_path" : null,
	"players" : {
		"foo" : {
			"squad" : "awesome squad",
			"x_res" : 1920,
			"y_res" : 1080
		},
		"bar" : {
			"squad" : "",
			"x_res" : 1024,
			"y_res" : 768
		}
	},
	"openskill_ratings" : {
		"foo" : {
			"mu" : 25.0,
			"sigma" : 8.333333333333334,
			"last_updated" : "2023-08-16 12:30"
		},
		"bar" : {
			"mu" : 25.0,
			"sigma" : 8.333333333333334,
			"last_updated" : "2023-08-16 12:30"
		}
	},
	"team_stats" : [
		{
			"freq" : 100,
			"is_winner" : true,
			"score" : 1,
			"player_slots" : [
				{
					"player_stats" : [
						{
							"player" : "foo",
							"play_duration" : "PT00:15:06.789",
							"lag_outs" : 0,
							"kills" : 0,
							"deaths" : 0,
							"knockouts" : 0,
							"team_kills" : 0,
							"solo_kills" : 0,
							"assists" : 0,
							"forced_reps" : 0,
							"gun_damage_dealt" : 4000,
							"bomb_damage_dealt" : 6000,
							"team_damage_dealt" : 1000,
							"gun_damage_taken" : 3636,
							"bomb_damage_taken" : 7222,
							"team_damage_taken" : 1234,
							"self_damage" : 400,
							"kill_damage" : 1000,
							"team_kill_damage" : 0,
							"forced_rep_damage" : 0,
							"bullet_fire_count" : 100,
							"bomb_fire_count" : 20,
							"mine_fire_count" : 1,
							"bullet_hit_count" : 10,
							"bomb_hit_count" : 10,
							"mine_hit_count" : 0,
							"first_out" : 0,
							"wasted_energy" : 1234,
							"wasted_repel" : 2,
							"wasted_rocket" : 2,
							"wasted_thor" : 0,
							"wasted_burst" : 0,
							"wasted_decoy" : 0,
							"wasted_portal" : 0,
							"wasted_brick" : 0,
							"ship_usage" : {
								"warbird" : "PT00:10:05.789",
								"spider" : "PT00:5:01"
							},
							"rating_change" : -4
						}
					]
				}
			]
		},
		{
			"freq" : 200,
			"is_winner" : false,
			"score" : 0,
			"player_slots" : [
				{
					"player_stats" : [
						{
							"player" : "bar",
							"play_duration" : "PT00:15:06.789",
							"lag_outs" : 0,
							"kills" : 0,
							"deaths" : 0,
							"knockouts" : 1,
							"team_kills" : 0,
							"solo_kills" : 0,
							"assists" : 0,
							"forced_reps" : 0,
							"gun_damage_dealt" : 4000,
							"bomb_damage_dealt" : 6000,
							"team_damage_dealt" : 1000,
							"gun_damage_taken" : 3636,
							"bomb_damage_taken" : 7222,
							"team_damage_taken" : 1234,
							"self_damage" : 400,
							"kill_damage" : 1000,
							"team_kill_damage" : 0,
							"forced_rep_damage" : 0,
							"bullet_fire_count" : 100,
							"bomb_fire_count" : 20,
							"mine_fire_count" : 1,
							"bullet_hit_count" : 10,
							"bomb_hit_count" : 10,
							"mine_hit_count" : 0,
							"first_out" : 3,
							"wasted_energy" : 1212,
							"wasted_repel" : 2,
							"wasted_rocket" : 2,
							"wasted_thor" : 0,
							"wasted_burst" : 0,
							"wasted_decoy" : 0,
							"wasted_portal" : 0,
							"wasted_brick" : 0,
							"ship_usage" : {
								"warbird" : "PT00:15:06.789"
							},
							"rating_change" : 4
						}
					]
				}
			]
		}
	],
	"events" : [
		{
			"event_type_id" : 1,
			"timestamp" : "2023-08-16 12:00",
			"freq" : 100,
			"slot_idx" : 1,
			"player" : "foo"
		},
		{
			"event_type_id" : 1,
			"timestamp" : "2023-08-16 12:00",
			"freq" : 200,
			"slot_idx" : 1,
			"player" : "bar"
		},
		{
			"event_type_id" : 3,
			"timestamp" : "2023-08-16 12:00",
			"player" : "foo",
			"ship" : 0
		},
		{
			"event_type_id" : 3,
			"timestamp" : "2023-08-16 12:00",
			"player" : "bar",
			"ship" : 6
		},
		{
			"event_type_id" : 2,
			"timestamp" : "2023-08-16 12:03",
			"killed_player" : "foo",
			"killer_player" : "bar",
			"is_knockout" : true,
			"is_team_kill" : false,
			"x_coord" : 8192,
			"y_coord": 8192,
			"killed_ship" : 0,
			"killer_ship" : 0,
			"score" : [0, 1],
			"remaining_slots" : [1, 1],
			"damage_stats" : {
				"bar" : 1000
			},
			"rating_changes" : {
				"foo" : -4,
				"bar" : 4
			}
		}
	]
}');

Usage (pb):
select ss.save_game('
{
	"game_type_id" : "10",
	"zone_server_name" : "Test Server",
	"arena" : "0",
	"box_number" : null,
	"lvl_file_name" : "pb.lvl",
	"lvl_checksum" : 12345,
	"start_timestamp" : "2023-08-17 15:04",
	"end_timestamp" : "2023-08-17 15:31",
	"replay_path" : null,
	"players" : {
		"foo" : {
			"squad" : "awesome squad",
			"x_res" : 1920,
			"y_res" : 1080
		},
		"bar" : {
			"squad" : "",
			"x_res" : 1024,
			"y_res" : 768
		},
		"baz" : {
			"squad" : "",
			"x_res" : 640,
			"y_res" : 480
		},
		"asdf" : {
			"squad" : "",
			"x_res" : 2560,
			"y_res" : 1440
		}
	},
	"pb_stats" : [
		{
			"freq" : 0,
			"score" : 6,
			"is_winner" : 1,
			"participants" : [
				{
					"player" : "foo",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				},
				{
					"player" : "baz",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				}
			]
		},
		{
			"freq" : 1,
			"score" : 4,
			"is_winner" : 0,
			"participants" : [
				{
					"player" : "bar",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				},
				{
					"player" : "asdf",
					"play_duration" : "PT00:04:21.251",
					"goals" : 2,
					"assists" : 3,
					"kills" : 20,
					"deaths" : 25,
					"ball_kills" : 3,
					"ball_deaths" : 5,
					"team_kills" : 0,
					"steals" : 4,
					"turnovers" : 2,
					"ball_spawns" : 3,
					"saves" : 3,
					"ball_carries" : 35,
					"rating" : 123
				}
			]
		}
	],
	"events" : [
		{
			"event_type_id" : 4,
			"timestamp" : "2023-08-16 12:01",
			"freq" : 100,
			"player" : "foo",
			"from_player" : "bar"
		},
		{
			"event_type_id" : 5,
			"timestamp" : "2023-08-16 12:04",
			"freq" : 200,
			"player" : "foo",
			"from_player" : "bar"
		},
		{
			"event_type_id" : 3,
			"timestamp" : "2023-08-16 12:05",
			"freq" : 100,
			"player" : "foo",
			"assists" : [ "baz" ]
		}
	]
}');

Usage (solo):
select ss.save_game('
{
	"game_type_id" : "1",
	"zone_server_name" : "Test Server",
	"arena" : "4v4pub",
	"box_number" : 1,
	"lvl_file_name" : "duel.lvl",
	"lvl_checksum" : 12345,
	"start_timestamp" : "2023-08-16 12:00",
	"end_timestamp" : "2023-08-16 12:30",
	"replay_path" : null,
	"players" : {
		"foo" : {
			"squad" : "awesome squad",
			"x_res" : 1920,
			"y_res" : 1080
		},
		"bar" : {
			"squad" : "",
			"x_res" : 1024,
			"y_res" : 768
		}
	},
	"solo_stats" : [
		{
			"player" : "foo",
			"play_duration" : "PT00:15:06.789",
			"ship_usage" : {
				"warbird" : "PT00:10:05.789",
				"spider" : "PT00:5:01"
			},
			"is_winner" : false,
			"score" : 0,
			"kills" : 0,
			"deaths" : 1,
			"end_energy" : 0,
			"gun_damage_dealt" : 1234,
			"bomb_damage_dealt" : 1234,
			"gun_damage_taken" : 1234,
			"bomb_damage_taken" : 1234,
			"self_damage" : 1234,
			"gun_fire_count" : 50,
			"bomb_fire_count" : 10,
			"mine_fire_count" : 1,
			"gun_hit_count" : 12,
			"bomb_hit_count" : 5,
			"mine_hit_count" : 1
		},
		{
			"player" : "bar",
			"play_duration" : "PT00:15:06.789",
			"ship_usage" : {
				"warbird" : "PT00:10:05.789"
			},
			"is_winner" : true,
			"score" : 1,
			"kills" : 1,
			"deaths" : 0,
			"end_energy" : 622,
			"gun_damage_dealt" : 1234,
			"bomb_damage_dealt" : 1234,
			"gun_damage_taken" : 1234,
			"bomb_damage_taken" : 1234,
			"self_damage" : 1234,
			"gun_fire_count" : 50,
			"bomb_fire_count" : 10,
			"mine_fire_count" : 1,
			"gun_hit_count" : 12,
			"bomb_hit_count" : 5,
			"mine_hit_count" : 1
		}
	],
	"events" : null
}');
*/

with cte_data as(
	select
		 gr.game_type_id
		,ss.get_or_insert_zone_server(gr.zone_server_name) as zone_server_id
		,ss.get_or_insert_arena(gr.arena) as arena_id
		,gr.box_number
		,ss.get_or_insert_lvl(gr.lvl_file_name, gr.lvl_checksum) as lvl_id
		,tstzrange(gr.start_timestamp, gr.end_timestamp, '[)') as time_played
		,gr.replay_path
		,gr.players
		,gr.openskill_ratings
		,gr.solo_stats
		,gr.team_stats
		,gr.pb_stats
		,gr.events
	from jsonb_to_record(p_game_json) as gr(
		 game_type_id bigint
		,zone_server_name character varying
		,arena character varying
		,box_number int
		,lvl_file_name character varying(16)
		,lvl_checksum integer
		,start_timestamp timestamptz
		,end_timestamp timestamptz
		,replay_path character varying
		,players jsonb
		,openskill_ratings jsonb
		,solo_stats jsonb
		,team_stats jsonb
		,pb_stats jsonb
		,events jsonb
	)		
)
,cte_player as(	
	select
		 ss.get_or_upsert_player(pe.key, pi.squad, pi.x_res, pi.y_res) as player_id
		,pe.key as player_name
	from cte_data as cd
	cross join jsonb_each(cd.players) as pe
	cross join jsonb_to_record(pe.value) as pi(
		 squad character varying(20)
		,x_res smallint
		,y_res smallint
	)
)
,cte_openskill_ratings as(
	select
		 p.player_id
		,ri.mu
		,ri.sigma
		,ri.last_updated
	from cte_data as cd
	cross join jsonb_each(cd.openskill_ratings) as re
	cross join jsonb_to_record(re.value) as ri(
		 mu double precision
		,sigma double precision
		,last_updated timestamptz
	)
	inner join cte_player as p
		on re.key = p.player_name
)
,cte_insert_player_mmr as(
	insert into ss.player_mmr(
		 player_id
		,game_type_id
		,mu
		,sigma
	)
	select
		 cor.player_id
		,cd.game_type_id
		,cor.mu
		,cor.sigma
	from cte_data as cd
	cross join cte_openskill_ratings as cor
	where cor.last_updated is null
		and not exists(
			select *
			from ss.player_mmr as pm
			where pm.player_id = cor.player_id
				and pm.game_type_id = cd.game_type_id
		)
)
,cte_update_player_mmr as(
	update ss.player_mmr as pm
	set  mu = cor.mu
		,sigma = cor.sigma
		,last_updated = current_timestamp
	from cte_openskill_ratings as cor
	where pm.player_id = cor.player_id
		and pm.game_type_id = (
			select game_type_id
			from cte_data
		)
		and pm.last_updated = cor.last_updated -- protect against overwriting newer data
)
,cte_game as(
	insert into ss.game(
		 game_type_id
		,zone_server_id
		,arena_id
		,box_number
		,time_played
		,replay_path
		,lvl_id
		,stat_period_id
	)
	select
		 game_type_id
		,zone_server_id
		,arena_id
		,box_number
		,time_played
		,replay_path
		,lvl_id
		,p_stat_period_id
	from cte_data
	returning game.game_id
)
,cte_solo_stats as(
	select
		 par.player as player_name
		,s.value as participant_json
	from cte_data as cd
	inner join ss.game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.solo_stats) as s
	cross join jsonb_to_record(s.value) as par(
		player character varying
	)
	where gt.game_mode_id = 1 -- 1v1
)
,cte_team_stats as(
	select
		 t.freq
		,t.is_winner
		,t.score
		,t.player_slots
	from cte_data as cd
	inner join ss.game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.team_stats) as j
	cross join jsonb_to_record(j.value) as t(
		 freq smallint
		,is_winner boolean
		,score integer
		,player_slots jsonb
	)
	where gt.game_mode_id = 2 -- Team Versus
)
,cte_versus_team as(
	insert into ss.versus_game_team(
		 game_id
		,freq
		,is_winner
		,score
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,ct.freq
		,ct.is_winner
		,ct.score
	from cte_team_stats as ct
	returning
		 freq
		,is_winner
)
,cte_team_members as(
	select
		 ct.freq
		,s.ordinality as slot_idx
		,tm.ordinality as member_idx
		,m.player as player_name
		,tm.value as team_member_json
	from cte_team_stats as ct
	cross join jsonb_array_elements(ct.player_slots) with ordinality as s
	cross join jsonb_array_elements(s.value->'player_stats') with ordinality as tm
	cross join jsonb_to_record(tm.value) as m(
		 player character varying(20)
	)
)
,cte_pb_teams as(
	select
		 t.freq
		,s.value as team_json
	from cte_data as cd
	inner join ss.game_type as gt
		on cd.game_type_id = gt.game_type_id
	cross join jsonb_array_elements(cd.pb_stats) as s
	cross join jsonb_to_record(s.value) as t(
		 freq smallint
	)
	where gt.game_mode_id = 3 -- Powerball
)
,cte_pb_participants as(
	select
		 ct.freq
		,par.player as player_name
		,ap.value as participant_json
	from cte_pb_teams as ct
	cross join jsonb_array_elements(ct.team_json->'participants') as ap
	cross join jsonb_to_record(ap.value) as par(
		 player character varying(20)
	)
)
,cte_solo_game_participant as(
	insert into ss.solo_game_participant(
		 game_id
		,player_id
		,play_duration
		,ship_mask
		,is_winner
		,score
		,kills
		,deaths
		,end_energy
		,gun_damage_dealt
		,bomb_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,self_damage
		,gun_fire_count
		,bomb_fire_count
		,mine_fire_count
		,gun_hit_count
		,bomb_hit_count
		,mine_hit_count
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,p.player_id
		,par.play_duration
		,cast(( 
			  case when su.warbird > cast('0' as interval) then 1 else 0 end
			| case when su.javelin > cast('0' as interval) then 2 else 0 end
			| case when su.spider > cast('0' as interval) then 4 else 0 end
			| case when su.leviathan > cast('0' as interval) then 8 else 0 end
			| case when su.terrier > cast('0' as interval) then 16 else 0 end
			| case when su.weasel > cast('0' as interval) then 32 else 0 end
			| case when su.lancaster > cast('0' as interval) then 64 else 0 end
			| case when su.shark > cast('0' as interval) then 128 else 0 end) as smallint
		 ) as ship_mask
		,par.is_winner
		,par.score
		,par.kills
		,par.deaths
		,par.end_energy
		,par.gun_damage_dealt
		,par.bomb_damage_dealt
		,par.gun_damage_taken
		,par.bomb_damage_taken
		,par.self_damage
		,par.gun_fire_count
		,par.bomb_fire_count
		,par.mine_fire_count
		,par.gun_hit_count
		,par.bomb_hit_count
		,par.mine_hit_count
	from cte_solo_stats as cs
	inner join cte_player as p
		on cs.player_name = p.player_name
	cross join jsonb_to_record(cs.participant_json) as par(
		 play_duration interval
		,ship_mask smallint
		,is_winner boolean
		,score integer
		,kills smallint
		,deaths smallint
		,end_energy smallint
		,gun_damage_dealt integer
		,bomb_damage_dealt integer
		,gun_damage_taken integer
		,bomb_damage_taken integer
		,self_damage integer
		,gun_fire_count integer
		,bomb_fire_count integer
		,mine_fire_count integer
		,gun_hit_count integer
		,bomb_hit_count integer
		,mine_hit_count integer
	)
	cross join jsonb_to_record(cs.participant_json->'ship_usage') as su(
		 warbird interval
		,javelin interval
		,spider interval
		,leviathan interval
		,terrier interval
		,weasel interval
		,lancaster interval
		,shark interval
	)
	returning
		 player_id
		,play_duration
		,ship_mask
		,is_winner
		,score
		,kills
		,deaths
		,end_energy
		,gun_damage_dealt
		,bomb_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,self_damage
		,gun_fire_count
		,bomb_fire_count
		,mine_fire_count
		,gun_hit_count
		,bomb_hit_count
		,mine_hit_count
)
,cte_pb_game_participant as(
	insert into ss.pb_game_participant(
		 game_id
		,freq
		,player_id
		,play_duration
		,goals
		,assists
		,kills
		,deaths
		,ball_kills
		,ball_deaths
		,team_kills
		,steals
		,turnovers
		,ball_spawns
		,saves
		,ball_carries
		,rating
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,cp.freq
		,p.player_id
		,par.play_duration
		,par.goals
		,par.assists
		,par.kills
		,par.deaths
		,par.ball_kills
		,par.ball_deaths
		,par.team_kills
		,par.steals
		,par.turnovers
		,par.ball_spawns
		,par.saves
		,par.ball_carries
		,par.rating
	from cte_pb_participants as cp
	inner join cte_player as p
		on cp.player_name = p.player_name
	cross join jsonb_to_record(cp.participant_json) as par(
		 play_duration interval
		,goals smallint
		,assists smallint
		,kills smallint
		,deaths smallint
		,ball_kills smallint
		,ball_deaths smallint
		,team_kills smallint
		,steals smallint
		,turnovers smallint
		,ball_spawns smallint
		,saves smallint
		,ball_carries smallint
		,rating smallint
	)
)
,cte_pb_game_score as(
	insert into ss.pb_game_score(
		 game_id
		,freq
		,score
		,is_winner
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,ct.freq
		,t.score
		,t.is_winner
	from cte_pb_teams as ct
	cross join jsonb_to_record(ct.team_json) as t(
		 score smallint
		,is_winner boolean
	)
)
,cte_player_ship_usage_data as(
	select
		 dt.player_id
		,(select game_type_id from cte_data) as game_type_id
		,sum(dt.warbird) as warbird_duration
		,sum(dt.javelin) as javelin_duration
		,sum(dt.spider) as spider_duration
		,sum(dt.leviathan) as leviathan_duration
		,sum(dt.terrier) as terrier_duration
		,sum(dt.weasel) as weasel_duration
		,sum(dt.lancaster) as lancaster_duration
		,sum(dt.shark) as shark_duration
	from(
		-- ship usage from solo stats
		select
			 p.player_id
			,su.warbird
			,su.javelin
			,su.spider
			,su.leviathan
			,su.terrier
			,su.weasel
			,su.lancaster
			,su.shark
		from cte_solo_stats as cs
		inner join cte_player as p
			on cs.player_name = p.player_name
		cross join jsonb_to_record(cs.participant_json->'ship_usage') as su(
			 warbird interval
			,javelin interval
			,spider interval
			,leviathan interval
			,terrier interval
			,weasel interval
			,lancaster interval
			,shark interval
		)
		union all
		-- ships usage from team stats
		select
			 p.player_id
			,su.warbird
			,su.javelin
			,su.spider
			,su.leviathan
			,su.terrier
			,su.weasel
			,su.lancaster
			,su.shark
		from cte_team_members as tm
		inner join cte_player as p
			on tm.player_name = p.player_name
		cross join jsonb_to_record(tm.team_member_json->'ship_usage') as su(
			 warbird interval
			,javelin interval
			,spider interval
			,leviathan interval
			,terrier interval
			,weasel interval
			,lancaster interval
			,shark interval
		)
	) as dt
	group by dt.player_id
)
,cte_versus_team_member as(
	insert into ss.versus_game_team_member(
		 game_id
		,freq
		,slot_idx
		,member_idx
		,player_id
		,premade_group
		,play_duration
		,ship_mask
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
		,rating_change
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
	)
	select
		 (select g.game_id from cte_game as g) as game_id
		,ctm.freq
		,ctm.slot_idx
		,ctm.member_idx
		,p.player_id
		,premade_group
		,m.play_duration
		,cast(( 
			  case when su.warbird > cast('0' as interval) then 1 else 0 end
			| case when su.javelin > cast('0' as interval) then 2 else 0 end
			| case when su.spider > cast('0' as interval) then 4 else 0 end
			| case when su.leviathan > cast('0' as interval) then 8 else 0 end
			| case when su.terrier > cast('0' as interval) then 16 else 0 end
			| case when su.weasel > cast('0' as interval) then 32 else 0 end
			| case when su.lancaster > cast('0' as interval) then 64 else 0 end
			| case when su.shark > cast('0' as interval) then 128 else 0 end) as smallint
		 ) as ship_mask
		,m.lag_outs
		,m.kills
		,m.deaths
		,m.knockouts
		,m.team_kills
		,m.solo_kills
		,m.assists
		,m.forced_reps
		,m.gun_damage_dealt
		,m.bomb_damage_dealt
		,m.team_damage_dealt
		,m.gun_damage_taken
		,m.bomb_damage_taken
		,m.team_damage_taken
		,m.self_damage
		,m.kill_damage
		,m.team_kill_damage
		,m.forced_rep_damage
		,m.bullet_fire_count
		,m.bomb_fire_count
		,m.mine_fire_count
		,m.bullet_hit_count
		,m.bomb_hit_count
		,m.mine_hit_count
		,coalesce(m.first_out, 0)
		,m.wasted_energy
		,coalesce(m.wasted_repel, 0)
		,coalesce(m.wasted_rocket, 0)
		,coalesce(m.wasted_thor, 0)
		,coalesce(m.wasted_burst, 0)
		,coalesce(m.wasted_decoy, 0)
		,coalesce(m.wasted_portal, 0)
		,coalesce(m.wasted_brick, 0)
		,m.rating_change
		,m.enemy_distance_sum
		,m.enemy_distance_samples
		,m.team_distance_sum
		,m.team_distance_samples
	from cte_team_members as ctm
	cross join jsonb_to_record(ctm.team_member_json) as m(
		 premade_group smallint
		,play_duration interval
		,lag_outs smallint
		,kills smallint
		,deaths smallint
		,knockouts smallint
		,team_kills smallint
		,solo_kills smallint
		,assists smallint
		,forced_reps smallint
		,gun_damage_dealt integer
		,bomb_damage_dealt integer
		,team_damage_dealt integer
		,gun_damage_taken integer
		,bomb_damage_taken integer
		,team_damage_taken integer
		,self_damage integer
		,kill_damage integer
		,team_kill_damage integer
		,forced_rep_damage integer
		,bullet_fire_count integer
		,bomb_fire_count integer
		,mine_fire_count integer
		,bullet_hit_count integer
		,bomb_hit_count integer
		,mine_hit_count integer
		,first_out smallint
		,wasted_energy integer
		,wasted_repel smallint
		,wasted_rocket smallint
		,wasted_thor smallint
		,wasted_burst smallint
		,wasted_decoy smallint
		,wasted_portal smallint
		,wasted_brick smallint
		,rating_change integer
		,enemy_distance_sum bigint
		,enemy_distance_samples int
		,team_distance_sum bigint
		,team_distance_samples int
	)
	cross join jsonb_to_record(ctm.team_member_json->'ship_usage') as su(
		 warbird interval
		,javelin interval
		,spider interval
		,leviathan interval
		,terrier interval
		,weasel interval
		,lancaster interval
		,shark interval
	)
	inner join cte_player as p
		on ctm.player_name = p.player_name
	returning
		 freq
		,player_id
		,play_duration
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
		,rating_change
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
)
,cte_events as(
	select
		 nextval('game_event_game_event_id_seq') as game_event_id
		,je.ordinality as event_idx
		,je.value as event_json
	from cte_data as cd
	cross join jsonb_array_elements(cd.events) with ordinality je
)
,cte_game_event as(
	insert into ss.game_event(
		 game_event_id
		,game_id
		,event_idx
		,game_event_type_id
		,event_timestamp
	)
	select
		 ce.game_event_id
		,(select g.game_id from cte_game as g) as game_id
		,ce.event_idx
		,e.event_type_id
		,e.timestamp
	from cte_events as ce
	cross join jsonb_to_record(ce.event_json) as e(
		 event_type_id bigint
		,timestamp timestamp
	)
	returning
		 game_event.game_event_id
		,game_event.game_event_type_id
)
,cte_versus_game_assign_slot_event as(
	insert into ss.versus_game_assign_slot_event(
		 game_event_id
		,freq
		,slot_idx
		,player_id
	)
	select
		 ce.game_event_id
		,e.freq
		,e.slot_idx
		,p.player_id
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as e(
		 freq smallint
		,slot_idx smallint
		,player character varying(20)
	)
	inner join cte_player as p
		on e.player = p.player_name
	where cme.game_event_type_id = 1 -- Assign Slot
)
,cte_versus_game_kill_event as(
	insert into ss.versus_game_kill_event(
		 game_event_id
		,killed_player_id
		,killer_player_id
		,is_knockout
		,is_team_kill
		,x_coord
		,y_coord
		,killed_ship
		,killer_ship
		,score
		,remaining_slots
	)
	select
		 ce.game_event_id
		,cp1.player_id
		,cp2.player_id
		,e.is_knockout
		,e.is_team_kill
		,e.x_coord
		,e.y_coord
		,e.killed_ship
		,e.killer_ship
		,e.score
		,e.remaining_slots
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as e(
		 killed_player character varying(20)
		,killer_player character varying(20)
		,is_knockout boolean
		,is_team_kill boolean
		,x_coord smallint
		,y_coord smallint
		,killed_ship smallint
		,killer_ship smallint
		,score integer[]
		,remaining_slots integer[]
	)
	inner join cte_player as cp1
		on e.killed_player = cp1.player_name
	inner join cte_player as cp2
		on e.killer_player = cp2.player_name
	where cme.game_event_type_id = 2 -- Kill
)
,cte_game_event_damage as(
	insert into ss.game_event_damage(
		 game_event_id
		,player_id
		,damage
	)
	select
		 cme.game_event_id
		,p.player_id
		,ds.value::integer as damage
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_each(ce.event_json->'damage_stats') as ds
	inner join cte_player as p
		on ds.key = p.player_name
)
,cte_game_ship_change_event as(
	insert into ss.game_ship_change_event(
		 game_event_id
		,player_id
		,ship
	)
	select
		 cge.game_event_id
		,p.player_id
		,sc.ship
	from cte_game_event as cge -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cge.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as sc(
		 player character varying(20)
		,ship smallint
	)
	inner join cte_player as p
		on sc.player = p.player_name
	where cge.game_event_type_id = 3 -- ship change
)
,cte_game_use_item_event as(
	insert into ss.game_use_item_event(
		 game_event_id
		,player_id
		,ship_item_id
	)
	select
		 cge.game_event_id
		,p.player_id
		,uie.ship_item_id
	from cte_game_event as cge
	inner join cte_events as ce
		on cge.game_event_id = ce.game_event_id
	cross join jsonb_to_record(ce.event_json) as uie(
		 player character varying(20)
		,ship_item_id smallint
	)
	inner join cte_player as p
		on uie.player = p.player_name
	where cge.game_event_type_id = 4 -- use item

)
,cte_game_event_rating as(
	insert into ss.game_event_rating(
		 game_event_id
		,player_id
		,rating
	)
	select
		 ce.game_event_id
		,cp.player_id
		,r.value::real as rating
	from cte_game_event as cme -- to ensure the game_event record was written before the current cte
	inner join cte_events as ce
		on cme.game_event_id = ce.game_event_id
	cross join jsonb_each(ce.event_json->'rating_changes') as r
	inner join cte_player as cp
		on r.key = cp.player_name
)
,cte_stat_periods as(
	-- regular games (p_stat_period_id is null) - apply to all stat periods that match by game_type_id and time_played
	select
		 sp.stat_period_id
		,st.is_rating_enabled
		,st.initial_rating
		,st.minimum_rating
	from cte_data as cd
	cross join ss.get_or_insert_stat_periods(cd.game_type_id, lower(cd.time_played)) as sp
	inner join stat_tracking as st
		on sp.stat_tracking_id = st.stat_tracking_id
	where p_stat_period_id is null
	union
	-- league matches (p_stat_period_id is not null) - apply to only the specified stat period and the lifetime/forever stat period
	select
		 sp.stat_period_id
		,st.is_rating_enabled
		,st.initial_rating
		,st.minimum_rating
	from cte_data as cd
	inner join ss.stat_tracking as st
		on cd.game_type_id = st.game_type_id
	inner join ss.stat_period as sp
		on st.stat_tracking_id = sp.stat_tracking_id
	where p_stat_period_id is not null
		and (sp.stat_period_id = p_stat_period_id
			or st.stat_period_type_id = 0 -- lifetime/forever
		)
)
,cte_player_solo_stats as(
	select
		 csgp.player_id
		,csp.stat_period_id
		,csgp.play_duration
		,csgp.is_winner
		,case when csgp.is_winner is false
			and exists( -- Another player is the winner
				select *
				from cte_solo_game_participant csgp2
				where csgp2.player_id <> csgp.player_id
					and csgp2.is_winner = true
			)
			then true
			else false
		 end is_loser
		,csgp.score
		,csgp.kills
		,csgp.deaths
		,csgp.gun_damage_dealt
		,csgp.bomb_damage_dealt
		,csgp.gun_damage_taken
		,csgp.bomb_damage_taken
		,csgp.self_damage
		,csgp.gun_fire_count
		,csgp.bomb_fire_count
		,csgp.mine_fire_count
		,csgp.gun_hit_count
		,csgp.bomb_hit_count
		,csgp.mine_hit_count
	from cte_data as cd
	cross join cte_solo_game_participant as csgp
	cross join cte_stat_periods as csp
)
,cte_insert_player_solo_stats as(
	insert into ss.player_solo_stats(
		 player_id
		,stat_period_id
		,games_played
		,play_duration
		,score
		,wins
		,losses
		,kills
		,deaths
		,gun_damage_dealt
		,bomb_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,self_damage
		,gun_fire_count
		,bomb_fire_count
		,mine_fire_count
		,gun_hit_count
		,bomb_hit_count
		,mine_hit_count
	)
	select
		 cs1.player_id
		,cs1.stat_period_id
		,1 as games_played
		,cs1.play_duration
		,cs1.score
		,case when is_winner = true then 1 else 0 end as wins
		,case when is_loser = true then 1 else 0 end as losses
		,cs1.kills
		,cs1.deaths
		,cs1.gun_damage_dealt
		,cs1.bomb_damage_dealt
		,cs1.gun_damage_taken
		,cs1.bomb_damage_taken
		,cs1.self_damage
		,cs1.gun_fire_count
		,cs1.bomb_fire_count
		,cs1.mine_fire_count
		,cs1.gun_hit_count
		,cs1.bomb_hit_count
		,cs1.mine_hit_count
	from cte_player_solo_stats cs1
	where not exists(
			select *
			from player_solo_stats as pss
			where pss.player_id = cs1.player_id
				and pss.stat_period_id = cs1.stat_period_id
		)
	returning
		 player_id
		,stat_period_id
)
,cte_update_player_solo_stats as(
	update ss.player_solo_stats as p
	set
		 games_played = p.games_played + 1
		,play_duration = p.play_duration + c.play_duration
		,score = p.score + c.score
		,wins = p.wins + case when c.is_winner = true then 1 else 0 end
		,losses = p.losses + case when c.is_loser = true then 1 else 0 end
		,kills = p.kills + c.kills
		,deaths = p.deaths + c.deaths
		,gun_damage_dealt = p.gun_damage_dealt + c.gun_damage_dealt
		,bomb_damage_dealt = p.bomb_damage_dealt + c.bomb_damage_dealt
		,gun_damage_taken = p.gun_damage_taken + c.gun_damage_taken
		,bomb_damage_taken = p.bomb_damage_taken + c.bomb_damage_taken
		,self_damage = p.self_damage + c.self_damage
		,gun_fire_count = p.gun_fire_count + c.gun_fire_count
		,bomb_fire_count = p.bomb_fire_count + c.bomb_fire_count
		,mine_fire_count = p.mine_fire_count + c.mine_fire_count
		,gun_hit_count = p.gun_hit_count + c.gun_hit_count
		,bomb_hit_count = p.bomb_hit_count + c.bomb_hit_count
		,mine_hit_count = p.mine_hit_count + c.mine_hit_count
	from cte_player_solo_stats c
	where p.player_id = c.player_id
		and p.stat_period_id = c.stat_period_id
		and not exists( -- not inserted
			select *
			from cte_insert_player_solo_stats as i
			where i.player_id = p.player_id
				and i.stat_period_id = p.stat_period_id
		)
)
,cte_player_versus_stats as(
	select
		 dt.player_id
		,dt.stat_period_id
		,count(*) filter(where dt.is_winner) as wins
		,count(*) filter(where dt.is_loser) as losses
		,sum(dt.play_duration) as play_duration
		,sum(dt.lag_outs) as lag_outs
		,sum(dt.kills) as kills
		,sum(dt.deaths) as deaths
		,sum(dt.knockouts) as knockouts
		,sum(dt.team_kills) as team_kills
		,sum(dt.solo_kills) as solo_kills
		,sum(dt.assists) as assists
		,sum(dt.forced_reps) as forced_reps
		,sum(dt.gun_damage_dealt) as gun_damage_dealt
		,sum(dt.bomb_damage_dealt) as bomb_damage_dealt
		,sum(dt.team_damage_dealt) as team_damage_dealt
		,sum(dt.gun_damage_taken) as gun_damage_taken
		,sum(dt.bomb_damage_taken) as bomb_damage_taken
		,sum(dt.team_damage_taken) as team_damage_taken
		,sum(dt.self_damage) as self_damage
		,sum(dt.kill_damage) as kill_damage
		,sum(dt.team_kill_damage) as team_kill_damage
		,sum(dt.forced_rep_damage) as forced_rep_damage
		,sum(dt.bullet_fire_count) as bullet_fire_count
		,sum(dt.bomb_fire_count) as bomb_fire_count
		,sum(dt.mine_fire_count) as mine_fire_count
		,sum(dt.bullet_hit_count) as bullet_hit_count
		,sum(dt.bomb_hit_count) as bomb_hit_count
		,sum(dt.mine_hit_count) as mine_hit_count
		,count(*) filter(where dt.first_out_regular) as first_out_regular
		,count(*) filter(where dt.first_out_critical) as first_out_critical
		,sum(dt.wasted_energy) as wasted_energy
		,sum(dt.wasted_repel) as wasted_repel
		,sum(dt.wasted_rocket) as wasted_rocket
		,sum(dt.wasted_thor) as wasted_thor
		,sum(dt.wasted_burst) as wasted_burst
		,sum(dt.wasted_decoy) as wasted_decoy
		,sum(dt.wasted_portal) as wasted_portal
		,sum(dt.wasted_brick) as wasted_brick
		,sum(dt.enemy_distance_sum) as enemy_distance_sum
		,sum(dt.enemy_distance_samples) as enemy_distance_samples
		,sum(dt.team_distance_sum) as team_distance_sum
		,sum(dt.team_distance_samples) as team_distance_samples
	from(
		select
			 cvtm.player_id
			,csp.stat_period_id
			,cvt.is_winner
			,(	case when cvt.is_winner = false
						and exists( -- another team got a win (possible there's no winner, for a draw)
							select *
							from cte_versus_team as cvt2
							where cvt2.freq <> cvtm.freq
								and cvt2.is_winner = true
						)
					then true
					else false
				end
			 ) as is_loser
			,cvtm.play_duration
			,cvtm.lag_outs
			,cvtm.kills
			,cvtm.deaths
			,cvtm.knockouts
			,cvtm.team_kills
			,cvtm.solo_kills
			,cvtm.assists
			,cvtm.forced_reps
			,cvtm.gun_damage_dealt
			,cvtm.bomb_damage_dealt
			,cvtm.team_damage_dealt
			,cvtm.gun_damage_taken
			,cvtm.bomb_damage_taken
			,cvtm.team_damage_taken
			,cvtm.self_damage
			,cvtm.kill_damage
			,cvtm.team_kill_damage
			,cvtm.forced_rep_damage
			,cvtm.bullet_fire_count
			,cvtm.bomb_fire_count
			,cvtm.mine_fire_count
			,cvtm.bullet_hit_count
			,cvtm.bomb_hit_count
			,cvtm.mine_hit_count
			,cvtm.first_out & 1 <> 0 as first_out_regular
			,cvtm.first_out & 2 <> 0 as first_out_critical
			,cvtm.wasted_energy
			,cvtm.wasted_repel
			,cvtm.wasted_rocket
			,cvtm.wasted_thor
			,cvtm.wasted_burst
			,cvtm.wasted_decoy
			,cvtm.wasted_portal
			,cvtm.wasted_brick
			,cvtm.enemy_distance_sum
			,cvtm.enemy_distance_samples
			,cvtm.team_distance_sum
			,cvtm.team_distance_samples
		from cte_data as cd
		cross join cte_versus_team_member as cvtm
		inner join cte_versus_team as cvt
			on cvtm.freq = cvt.freq
		cross join cte_stat_periods as csp
	) as dt
	group by -- in case the player played on multiple teams
		 dt.player_id
		,dt.stat_period_id
)
,cte_insert_player_versus_stats as(
	insert into ss.player_versus_stats(
		 player_id
		,stat_period_id
		,wins
		,losses
		,games_played
		,play_duration
		,lag_outs
		,kills
		,deaths
		,knockouts
		,team_kills
		,solo_kills
		,assists
		,forced_reps
		,gun_damage_dealt
		,bomb_damage_dealt
		,team_damage_dealt
		,gun_damage_taken
		,bomb_damage_taken
		,team_damage_taken
		,self_damage
		,kill_damage
		,team_kill_damage
		,forced_rep_damage
		,bullet_fire_count
		,bomb_fire_count
		,mine_fire_count
		,bullet_hit_count
		,bomb_hit_count
		,mine_hit_count
		,first_out_regular
		,first_out_critical
		,wasted_energy
		,wasted_repel
		,wasted_rocket
		,wasted_thor
		,wasted_burst
		,wasted_decoy
		,wasted_portal
		,wasted_brick
		,enemy_distance_sum
		,enemy_distance_samples
		,team_distance_sum
		,team_distance_samples
	)
	select
		 cpvs.player_id
		,cpvs.stat_period_id
		,cpvs.wins
		,cpvs.losses
		,1 -- if we're inserting, this is the first game
		,cpvs.play_duration
		,cpvs.lag_outs
		,cpvs.kills
		,cpvs.deaths
		,cpvs.knockouts
		,cpvs.team_kills
		,cpvs.solo_kills
		,cpvs.assists
		,cpvs.forced_reps
		,cpvs.gun_damage_dealt
		,cpvs.bomb_damage_dealt
		,cpvs.team_damage_dealt
		,cpvs.gun_damage_taken
		,cpvs.bomb_damage_taken
		,cpvs.team_damage_taken
		,cpvs.self_damage
		,cpvs.kill_damage
		,cpvs.team_kill_damage
		,cpvs.forced_rep_damage
		,cpvs.bullet_fire_count
		,cpvs.bomb_fire_count
		,cpvs.mine_fire_count
		,cpvs.bullet_hit_count
		,cpvs.bomb_hit_count
		,cpvs.mine_hit_count
		,cpvs.first_out_regular
		,cpvs.first_out_critical
		,cpvs.wasted_energy
		,cpvs.wasted_repel
		,cpvs.wasted_rocket
		,cpvs.wasted_thor
		,cpvs.wasted_burst
		,cpvs.wasted_decoy
		,cpvs.wasted_portal
		,cpvs.wasted_brick
		,cpvs.enemy_distance_sum
		,cpvs.enemy_distance_samples
		,cpvs.team_distance_sum
		,cpvs.team_distance_samples
	from cte_player_versus_stats as cpvs
	where not exists(
			select *
			from ss.player_versus_stats as pvs
			where pvs.player_id = cpvs.player_id
				and pvs.stat_period_id = cpvs.stat_period_id
		)
	returning
		 player_id
		,stat_period_id
)
,cte_update_player_versus_stats as(
	update ss.player_versus_stats as pvs
	set  wins = pvs.wins + cpvs.wins
		,losses = pvs.losses + cpvs.losses
		,games_played = pvs.games_played + 1
		,play_duration = pvs.play_duration + cpvs.play_duration
		,lag_outs = pvs.lag_outs + cpvs.lag_outs
		,kills = pvs.kills + cpvs.kills
		,deaths = pvs.deaths + cpvs.deaths
		,knockouts = pvs.knockouts + cpvs.knockouts
		,team_kills = pvs.team_kills + cpvs.team_kills
		,solo_kills = pvs.solo_kills + cpvs.solo_kills
		,assists = pvs.assists + cpvs.assists
		,forced_reps = pvs.forced_reps + cpvs.forced_reps
		,gun_damage_dealt = pvs.gun_damage_dealt + cpvs.gun_damage_dealt
		,bomb_damage_dealt = pvs.bomb_damage_dealt + cpvs.bomb_damage_dealt
		,team_damage_dealt = pvs.team_damage_dealt + cpvs.team_damage_dealt
		,gun_damage_taken = pvs.gun_damage_taken + cpvs.gun_damage_taken
		,bomb_damage_taken = pvs.bomb_damage_taken + cpvs.bomb_damage_taken
		,team_damage_taken = pvs.team_damage_taken + cpvs.team_damage_taken
		,self_damage = pvs.self_damage + cpvs.self_damage
		,kill_damage = pvs.kill_damage + cpvs.kill_damage
		,team_kill_damage = pvs.team_kill_damage + cpvs.team_kill_damage
		,forced_rep_damage = pvs.forced_rep_damage + cpvs.forced_rep_damage
		,bullet_fire_count = pvs.bullet_fire_count + cpvs.bullet_fire_count
		,bomb_fire_count = pvs.bomb_fire_count + cpvs.bomb_fire_count
		,mine_fire_count = pvs.mine_fire_count + cpvs.mine_fire_count
		,bullet_hit_count = pvs.bullet_hit_count + cpvs.bullet_hit_count
		,bomb_hit_count = pvs.bomb_hit_count + cpvs.bomb_hit_count
		,mine_hit_count = pvs.mine_hit_count + cpvs.mine_hit_count
		,first_out_regular = pvs.first_out_regular + cpvs.first_out_regular
		,first_out_critical = pvs.first_out_critical + cpvs.first_out_critical
		,wasted_energy = pvs.wasted_energy + cpvs.wasted_energy
		,wasted_repel = pvs.wasted_repel + cpvs.wasted_repel
		,wasted_rocket = pvs.wasted_rocket + cpvs.wasted_rocket
		,wasted_thor = pvs.wasted_thor + cpvs.wasted_thor
		,wasted_burst = pvs.wasted_burst + cpvs.wasted_burst
		,wasted_decoy = pvs.wasted_decoy + cpvs.wasted_decoy
		,wasted_portal = pvs.wasted_portal + cpvs.wasted_portal
		,wasted_brick = pvs.wasted_brick + cpvs.wasted_brick
		,enemy_distance_sum = 
			case when pvs.enemy_distance_sum is null and cpvs.enemy_distance_sum is null
				then null
				else coalesce(pvs.enemy_distance_sum, 0) + coalesce(cpvs.enemy_distance_sum, 0)
			end
		,enemy_distance_samples = 
			case when pvs.enemy_distance_samples is null and cpvs.enemy_distance_samples is null
				then null
				else coalesce(pvs.enemy_distance_samples, 0) + coalesce(cpvs.enemy_distance_samples, 0)
			end
		,team_distance_sum = 
			case when pvs.team_distance_sum is null and cpvs.team_distance_sum is null
				then null
				else coalesce(pvs.team_distance_sum, 0) + coalesce(cpvs.team_distance_sum, 0)
			end
		,team_distance_samples = 
			case when pvs.team_distance_samples is null and cpvs.team_distance_samples is null
				then null
				else coalesce(pvs.team_distance_samples, 0) + coalesce(cpvs.team_distance_samples, 0)
			end
	from cte_player_versus_stats as cpvs
	where pvs.player_id = cpvs.player_id
		and pvs.stat_period_id = cpvs.stat_period_id
		and not exists( -- TODO: this might not be needed since this cte can't see the rows inserted by cte_insert_player_versus_stats?
			select *
			from cte_insert_player_versus_stats as i
			where i.player_id = cpvs.player_id
				and i.stat_period_id = cpvs.stat_period_id
		)
)
-- TODO: pb
--,cte_insert_player_pb_stats as(
--)
--,cte_update_player_pb_stats as(
--)
,cte_insert_player_rating as(
	insert into ss.player_rating(
		 player_id
		,stat_period_id
		,rating
	)
	select
		 dt.player_id
		,csp.stat_period_id
		,greatest(csp.initial_rating + dt.rating_change, csp.minimum_rating)
	from cte_stat_periods as csp
	cross join(
		select
			 cvtm.player_id
			,sum(cvtm.rating_change) as rating_change
		from cte_versus_team_member as cvtm
		group by cvtm.player_id
	) as dt
	where csp.is_rating_enabled = true
		and not exists(
			select *
			from ss.player_rating as pr
			where pr.player_id = dt.player_id
				and pr.stat_period_id = csp.stat_period_id
		)
	returning
		 player_id
		,stat_period_id
)
,cte_update_player_rating as(
	update ss.player_rating as pr
	set rating = greatest(pr.rating + dt.rating_change, csp.minimum_rating)
	from cte_stat_periods as csp
	cross join(
		select
			 cvtm.player_id
			,sum(cvtm.rating_change) as rating_change
		from cte_versus_team_member as cvtm
		group by cvtm.player_id
	) as dt
	where csp.is_rating_enabled = true
		and pr.player_id = dt.player_id
		and pr.stat_period_id = csp.stat_period_id
		and not exists( -- TODO: this might not be needed since this cte can't see the rows inserted by cte_insert_player_rating?
			select *
			from cte_insert_player_rating as i
			where i.player_id = dt.player_id
				and i.stat_period_id = csp.stat_period_id
		)
)
,cte_update_player_ship_usage as(
	update ss.player_ship_usage as psu
	set
		 warbird_use = psu.warbird_use + case when c.warbird_duration > cast('0' as interval) then 1 else 0 end
		,javelin_use = psu.javelin_use + case when c.javelin_duration > cast('0' as interval) then 1 else 0 end
		,spider_use = psu.spider_use + case when c.spider_duration > cast('0' as interval) then 1 else 0 end
		,leviathan_use = psu.leviathan_use + case when c.leviathan_duration > cast('0' as interval) then 1 else 0 end
		,terrier_use = psu.terrier_use + case when c.terrier_duration > cast('0' as interval) then 1 else 0 end
		,weasel_use = psu.weasel_use + case when c.weasel_duration > cast('0' as interval) then 1 else 0 end
		,lancaster_use = psu.lancaster_use + case when c.lancaster_duration > cast('0' as interval) then 1 else 0 end
		,shark_use = psu.shark_use + case when c.shark_duration > cast('0' as interval) then 1 else 0 end
		,warbird_duration = psu.warbird_duration + coalesce(c.warbird_duration, cast('0' as interval))
		,javelin_duration = psu.javelin_duration + coalesce(c.javelin_duration, cast('0' as interval))
		,spider_duration = psu.spider_duration + coalesce(c.spider_duration, cast('0' as interval))
		,leviathan_duration = psu.leviathan_duration + coalesce(c.leviathan_duration, cast('0' as interval))
		,terrier_duration = psu.terrier_duration + coalesce(c.terrier_duration, cast('0' as interval))
		,weasel_duration = psu.weasel_duration + coalesce(c.weasel_duration, cast('0' as interval))
		,lancaster_duration = psu.lancaster_duration + coalesce(c.lancaster_duration, cast('0' as interval))
		,shark_duration = psu.shark_duration + coalesce(c.shark_duration, cast('0' as interval))
	from cte_player_ship_usage_data as c
	cross join cte_stat_periods as csp
	where psu.player_id = c.player_id
		and psu.stat_period_id = csp.stat_period_id
)
,cte_insert_player_ship_usage as(
	insert into ss.player_ship_usage(
		 player_id
		,stat_period_id
		,warbird_use
		,javelin_use
		,spider_use
		,leviathan_use
		,terrier_use
		,weasel_use
		,lancaster_use
		,shark_use
		,warbird_duration
		,javelin_duration
		,spider_duration
		,leviathan_duration
		,terrier_duration
		,weasel_duration
		,lancaster_duration
		,shark_duration
	)
	select
		 c.player_id
		,csp.stat_period_id
		,case when c.warbird_duration > cast('0' as interval) then 1 else 0 end
		,case when c.javelin_duration > cast('0' as interval) then 1 else 0 end
		,case when c.spider_duration > cast('0' as interval) then 1 else 0 end
		,case when c.leviathan_duration > cast('0' as interval) then 1 else 0 end
		,case when c.terrier_duration > cast('0' as interval) then 1 else 0 end
		,case when c.weasel_duration > cast('0' as interval) then 1 else 0 end
		,case when c.lancaster_duration > cast('0' as interval) then 1 else 0 end
		,case when c.shark_duration > cast('0' as interval) then 1 else 0 end
		,coalesce(c.warbird_duration, cast('0' as interval))
		,coalesce(c.javelin_duration, cast('0' as interval))
		,coalesce(c.spider_duration, cast('0' as interval))
		,coalesce(c.leviathan_duration, cast('0' as interval))
		,coalesce(c.terrier_duration, cast('0' as interval))
		,coalesce(c.weasel_duration, cast('0' as interval))
		,coalesce(c.lancaster_duration, cast('0' as interval))
		,coalesce(c.shark_duration, cast('0' as interval))
	from cte_player_ship_usage_data as c
	cross join cte_stat_periods as csp
	where not exists(
			select *
			from ss.player_ship_usage as psu
			where psu.player_id = c.player_id
				and psu.stat_period_id = csp.stat_period_id
		)
)
select cm.game_id
from cte_game as cm;

$$;

alter function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type
) owner to ss_developer;

revoke all on function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type
) from public;

grant execute on function ss.save_game(
	 p_game_json jsonb
	,p_stat_period_id ss.stat_period.stat_period_id%type
) to ss_zone_server;
