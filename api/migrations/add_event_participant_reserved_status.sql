-- Migration: allow status 'reserved' on event_participants (organizer-held slot for a member).
-- Run on each tenant database.

ALTER TABLE event_participants DROP CONSTRAINT IF EXISTS event_participants_status_check;

ALTER TABLE event_participants ADD CONSTRAINT event_participants_status_check
  CHECK (status IN ('joined', 'waitlisted', 'withdrawn', 'no_show', 'confirmed', 'reserved'));

DROP INDEX IF EXISTS idx_event_participants_event_slot_active;

CREATE UNIQUE INDEX IF NOT EXISTS idx_event_participants_event_slot_active
ON event_participants (event_id, slot_index)
WHERE slot_index IS NOT NULL AND status IN ('joined', 'confirmed', 'reserved');

COMMENT ON COLUMN event_participants.status IS
  'joined|waitlisted|withdrawn|no_show|confirmed|reserved. reserved = slot held for a member until they claim or organizer removes.';
