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