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