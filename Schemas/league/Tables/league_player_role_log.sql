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