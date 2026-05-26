-- Match events + per-event participants (RSVP / waitlist).
-- See: Cogento/docs/MATCH_EVENTS_DESIGN.md sections 4.1 and 4.2.
-- Run once per existing tenant database. Idempotent.
-- New tenants: same DDL lives in bootstrap_tenant_schema.sql.

-- ============================================================================
-- EVENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS events (
    event_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name              VARCHAR(200) NOT NULL,
    description       TEXT,

    sport             VARCHAR(30) NOT NULL DEFAULT 'tennis',
    format            VARCHAR(30) NOT NULL DEFAULT 'doubles',

    event_type        VARCHAR(30) NOT NULL DEFAULT 'single_match'
      CHECK (event_type IN ('single_match','round_robin','freeform_tournament','bracket')),

    scheduled_start   TIMESTAMP WITH TIME ZONE,
    scheduled_end     TIMESTAMP WITH TIME ZONE,
    location          VARCHAR(255),

    capacity          INTEGER NOT NULL CHECK (capacity > 0),
    min_participants  INTEGER,
    join_policy       VARCHAR(30) NOT NULL DEFAULT 'open'
      CHECK (join_policy IN ('open','approval','invite_only')),

    status            VARCHAR(30) NOT NULL DEFAULT 'scheduled'
      CHECK (status IN ('draft','scheduled','open','closed','in_progress','completed','cancelled')),

    created_by_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    created_by_email   VARCHAR(255) NOT NULL,

    metadata           JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_scheduled_start ON events(scheduled_start);
CREATE INDEX IF NOT EXISTS idx_events_status          ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_event_type      ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created_by_user ON events(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_events_metadata_gin    ON events USING GIN(metadata);

COMMENT ON TABLE events IS 'Scheduled match events members can join; created_by_email portable across user deletion.';
COMMENT ON COLUMN events.capacity IS 'Max joined participants. v1 single_match doubles = 4; enforced at app layer for event_type-specific caps.';
COMMENT ON COLUMN events.metadata IS 'Free-form tenant additions (cost, member-only, court, level cap, etc.).';

-- ============================================================================
-- EVENT_PARTICIPANTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS event_participants (
    participant_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id          UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,

    email             VARCHAR(255) NOT NULL,
    user_id           UUID REFERENCES users(user_id) ON DELETE SET NULL,

    role              VARCHAR(30) NOT NULL DEFAULT 'player'
      CHECK (role IN ('player','organizer','umpire','spectator')),

    status            VARCHAR(30) NOT NULL DEFAULT 'joined'
      CHECK (status IN ('joined','waitlisted','withdrawn','no_show','confirmed','reserved')),

    joined_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    withdrew_at       TIMESTAMP WITH TIME ZONE,

    slot_index        SMALLINT,

    metadata          JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE (event_id, email)
);

CREATE INDEX IF NOT EXISTS idx_event_participants_event_id ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_user_id  ON event_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_email    ON event_participants(email);
CREATE INDEX IF NOT EXISTS idx_event_participants_status   ON event_participants(status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_event_participants_event_slot_active
ON event_participants (event_id, slot_index)
WHERE slot_index IS NOT NULL AND status IN ('joined', 'confirmed', 'reserved');

CREATE INDEX IF NOT EXISTS idx_event_participants_slot ON event_participants(event_id, slot_index);

COMMENT ON TABLE event_participants IS 'Per-event RSVP rows; UNIQUE(event_id,email) means re-joining after withdraw flips status, not duplicates.';
COMMENT ON COLUMN event_participants.slot_index IS '1..capacity roster slot for joined/confirmed; NULL for waitlisted.';
COMMENT ON COLUMN event_participants.status IS 'joined|waitlisted|withdrawn|no_show|confirmed. Capacity hard cap on joined enforced at app layer (see MATCH_EVENTS_DESIGN.md §1.3).';
