-- Ratings (CMR and future rating types) + match results for doubles tennis CMR.
-- Run once per existing tenant database. Idempotent.
-- New tenants: tables are included in bootstrap_tenant_schema.sql.

CREATE TABLE IF NOT EXISTS ratings (
    rating_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email                  VARCHAR(255) NOT NULL,
    user_id                UUID REFERENCES users(user_id) ON DELETE SET NULL,

    rating_category        VARCHAR(50) NOT NULL,
    rating_type            VARCHAR(50) NOT NULL,

    rating                 NUMERIC(6,3),
    reliability            SMALLINT CHECK (reliability BETWEEN 0 AND 100),
    confidence_low         NUMERIC(6,3),
    confidence_high        NUMERIC(6,3),

    internal_rating        NUMERIC(8,3),
    match_count            INTEGER NOT NULL DEFAULT 0,
    last_match_at          TIMESTAMP WITH TIME ZONE,

    source                 VARCHAR(30) NOT NULL
      CHECK (source IN ('computed','external','manual_admin','self_assessed')),
    source_ref             TEXT,
    explanation            TEXT,

    settings_version       INTEGER,
    last_calculated_at     TIMESTAMP WITH TIME ZONE,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at             TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE (email, rating_category, rating_type)
);

CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_category_type_value ON ratings(rating_category, rating_type, rating DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_ratings_last_calculated_at ON ratings(last_calculated_at);

COMMENT ON TABLE ratings IS 'Per-member ratings (CMR etc.); portable subject key is email; user_id is optional host join.';

CREATE TABLE IF NOT EXISTS matches (
    match_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    played_at         DATE NOT NULL,
    format            VARCHAR(20) NOT NULL DEFAULT 'doubles'
                       CHECK (format IN ('doubles','singles')),

    team_a_p1_id      UUID REFERENCES users(user_id) ON DELETE SET NULL,
    team_a_p2_id      UUID REFERENCES users(user_id) ON DELETE SET NULL,
    team_b_p1_id      UUID REFERENCES users(user_id) ON DELETE SET NULL,
    team_b_p2_id      UUID REFERENCES users(user_id) ON DELETE SET NULL,

    team_a_sets       SMALLINT,
    team_b_sets       SMALLINT,
    team_a_games      SMALLINT,
    team_b_games      SMALLINT,
    raw_score         TEXT,

    source            VARCHAR(50) NOT NULL DEFAULT 'manual'
                       CHECK (source IN ('manual','csv_import','event')),
    import_batch_id   UUID,
    event_id          UUID,

    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_matches_played_at ON matches(played_at);
CREATE INDEX IF NOT EXISTS idx_matches_team_a_p1 ON matches(team_a_p1_id);
CREATE INDEX IF NOT EXISTS idx_matches_team_a_p2 ON matches(team_a_p2_id);
CREATE INDEX IF NOT EXISTS idx_matches_team_b_p1 ON matches(team_b_p1_id);
CREATE INDEX IF NOT EXISTS idx_matches_team_b_p2 ON matches(team_b_p2_id);
CREATE INDEX IF NOT EXISTS idx_matches_import_batch ON matches(import_batch_id);
CREATE INDEX IF NOT EXISTS idx_matches_event_id ON matches(event_id);

COMMENT ON TABLE matches IS 'Match results for CMR; source=manual|csv_import|event. import_batch_id and event_id are soft UUIDs (no FK) so the module is portable.';
COMMENT ON COLUMN matches.event_id IS 'Optional link to events when match-events feature ships; no FK in v1 to avoid table ordering dependency.';
COMMENT ON COLUMN matches.format IS 'doubles uses all four player slots; singles uses only team_a_p1_id and team_b_p1_id (team_*_p2_id nullable for singles).';
