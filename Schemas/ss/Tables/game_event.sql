-- Table: ss.game_event

-- DROP TABLE IF EXISTS ss.game_event;

CREATE TABLE IF NOT EXISTS ss.game_event
(
    game_event_id bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    game_id bigint NOT NULL,
    event_idx integer NOT NULL,
    game_event_type_id bigint NOT NULL,
    event_timestamp timestamp with time zone NOT NULL,
    CONSTRAINT game_event_pkey PRIMARY KEY (game_event_id),
    CONSTRAINT game_event_game_id_event_idx_key UNIQUE (game_id, event_idx),
    CONSTRAINT game_event_event_type_id_fkey FOREIGN KEY (game_event_type_id)
        REFERENCES ss.game_event_type (game_event_type_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT game_event_game_id_fkey FOREIGN KEY (game_id)
        REFERENCES ss.game (game_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.game_event
    OWNER to postgres;