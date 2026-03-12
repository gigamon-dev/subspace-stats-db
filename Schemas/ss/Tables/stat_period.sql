-- Table: ss.stat_period

-- DROP TABLE IF EXISTS ss.stat_period;

CREATE TABLE IF NOT EXISTS ss.stat_period
(
    stat_period_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    stat_tracking_id bigint NOT NULL,
    period_range tstzrange NOT NULL,
    CONSTRAINT stat_period_pkey PRIMARY KEY (stat_period_id),
    CONSTRAINT stat_period_stat_tracking_id_fkey FOREIGN KEY (stat_tracking_id)
        REFERENCES ss.stat_tracking (stat_tracking_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.stat_period
    OWNER to ss_developer;