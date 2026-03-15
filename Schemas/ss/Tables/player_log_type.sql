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