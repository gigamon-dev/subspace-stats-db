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