-- Table: league.team

-- DROP TABLE IF EXISTS league.team;

CREATE TABLE IF NOT EXISTS league.team
(
    team_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    team_name character varying(20) COLLATE pg_catalog."default" NOT NULL,
    season_id bigint NOT NULL,
    banner_small character varying(255) COLLATE pg_catalog."default",
    banner_large character varying(255) COLLATE pg_catalog."default",
    wins integer,
    losses integer,
    draws integer,
    is_enabled boolean NOT NULL DEFAULT true,
    franchise_id bigint,
    CONSTRAINT team_pkey PRIMARY KEY (team_id),
    CONSTRAINT team_franchise_id_fkey FOREIGN KEY (franchise_id)
        REFERENCES league.franchise (franchise_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT team_season_id_fkey FOREIGN KEY (season_id)
        REFERENCES league.season (season_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS league.team
    OWNER to ss_developer;
-- Index: team_season_id_team_name_team_id_idx

-- DROP INDEX IF EXISTS league.team_season_id_team_name_team_id_idx;

CREATE INDEX IF NOT EXISTS team_season_id_team_name_team_id_idx
    ON league.team USING btree
    (season_id ASC NULLS LAST, team_name COLLATE pg_catalog."default" ASC NULLS LAST)
    INCLUDE(team_id)
    WITH (deduplicate_items=True)
    TABLESPACE pg_default;