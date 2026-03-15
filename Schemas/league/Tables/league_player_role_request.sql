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