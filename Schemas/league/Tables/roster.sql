-- Table: league.roster

-- DROP TABLE IF EXISTS league.roster;

CREATE TABLE IF NOT EXISTS league.roster
(
    season_id bigint NOT NULL,
    player_id bigint NOT NULL,
    signup_timestamp time with time zone NOT NULL,
    team_id bigint,
    enroll_timestamp timestamp with time zone,
    is_captain boolean NOT NULL,
    CONSTRAINT roster_pkey PRIMARY KEY (season_id, player_id),
    CONSTRAINT roster_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT roster_team_id_fkey FOREIGN KEY (team_id)
        REFERENCES league.team (team_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.roster
    OWNER to ss_developer;
-- Index: roster_player_id_season_id_idx

-- DROP INDEX IF EXISTS league.roster_player_id_season_id_idx;

CREATE INDEX IF NOT EXISTS roster_player_id_season_id_idx
    ON league.roster USING btree
    (player_id ASC NULLS LAST)
    INCLUDE(season_id)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;