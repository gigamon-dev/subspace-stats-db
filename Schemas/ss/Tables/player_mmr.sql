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