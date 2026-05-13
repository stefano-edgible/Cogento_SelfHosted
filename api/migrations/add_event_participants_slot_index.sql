-- Roster slot index for event participants (click-to-join matrix UI).
-- Idempotent. Run per existing tenant DB. New tenants: column in bootstrap_tenant_schema.sql.

ALTER TABLE event_participants ADD COLUMN IF NOT EXISTS slot_index SMALLINT;

COMMENT ON COLUMN event_participants.slot_index IS '1..event.capacity for joined/confirmed roster position; NULL for waitlisted or legacy rows.';

-- At most one active player per physical slot per event.
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_participants_event_slot_active
ON event_participants (event_id, slot_index)
WHERE slot_index IS NOT NULL AND status IN ('joined', 'confirmed');

CREATE INDEX IF NOT EXISTS idx_event_participants_slot ON event_participants(event_id, slot_index);
