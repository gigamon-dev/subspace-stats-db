-- Table: ss.player_versus_stats

-- DROP TABLE IF EXISTS ss.player_versus_stats;

CREATE TABLE IF NOT EXISTS ss.player_versus_stats
(
    player_id bigint NOT NULL,
    stat_period_id bigint NOT NULL,
    games_played bigint NOT NULL,
    play_duration interval NOT NULL,
    wins bigint NOT NULL,
    losses bigint NOT NULL,
    lag_outs bigint NOT NULL,
    kills bigint NOT NULL,
    deaths bigint NOT NULL,
    knockouts bigint NOT NULL,
    team_kills bigint NOT NULL,
    solo_kills bigint NOT NULL,
    assists bigint NOT NULL,
    forced_reps bigint NOT NULL,
    gun_damage_dealt bigint NOT NULL,
    bomb_damage_dealt bigint NOT NULL,
    team_damage_dealt bigint NOT NULL,
    gun_damage_taken bigint NOT NULL,
    bomb_damage_taken bigint NOT NULL,
    team_damage_taken bigint NOT NULL,
    self_damage bigint NOT NULL,
    kill_damage bigint NOT NULL,
    team_kill_damage bigint NOT NULL,
    forced_rep_damage bigint NOT NULL,
    bullet_fire_count bigint NOT NULL,
    bomb_fire_count bigint NOT NULL,
    mine_fire_count bigint NOT NULL,
    bullet_hit_count bigint NOT NULL,
    bomb_hit_count bigint NOT NULL,
    mine_hit_count bigint NOT NULL,
    first_out_regular bigint NOT NULL,
    first_out_critical bigint NOT NULL,
    wasted_energy bigint NOT NULL,
    wasted_repel bigint NOT NULL,
    wasted_rocket bigint NOT NULL,
    wasted_thor bigint NOT NULL,
    wasted_burst bigint NOT NULL,
    wasted_decoy bigint NOT NULL,
    wasted_portal bigint NOT NULL,
    wasted_brick bigint NOT NULL,
    enemy_distance_sum bigint,
    enemy_distance_samples bigint,
    team_distance_sum bigint,
    team_distance_samples bigint,
    rating_sum bigint NOT NULL,
    rating_avg real GENERATED ALWAYS AS (((rating_sum)::real / (games_played)::real)) STORED,
    CONSTRAINT player_versus_stats_pkey PRIMARY KEY (player_id, stat_period_id),
    CONSTRAINT player_versus_stats_player_id_fkey FOREIGN KEY (player_id)
        REFERENCES ss.player (player_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT player_versus_stats_stat_period_id_fkey FOREIGN KEY (stat_period_id)
        REFERENCES ss.stat_period (stat_period_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS ss.player_versus_stats
    OWNER to ss_developer;
-- Index: player_versus_stats_stat_period_id_player_id_idx

-- DROP INDEX IF EXISTS ss.player_versus_stats_stat_period_id_player_id_idx;

CREATE INDEX IF NOT EXISTS player_versus_stats_stat_period_id_player_id_idx
    ON ss.player_versus_stats USING btree
    (stat_period_id ASC NULLS LAST, player_id ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: player_versus_stats_stat_period_id_rating_avg_player_id_idx

-- DROP INDEX IF EXISTS ss.player_versus_stats_stat_period_id_rating_avg_player_id_idx;

CREATE INDEX IF NOT EXISTS player_versus_stats_stat_period_id_rating_avg_player_id_idx
    ON ss.player_versus_stats USING btree
    (stat_period_id ASC NULLS LAST, rating_avg DESC NULLS FIRST)
    INCLUDE(player_id)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;