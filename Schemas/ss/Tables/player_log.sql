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