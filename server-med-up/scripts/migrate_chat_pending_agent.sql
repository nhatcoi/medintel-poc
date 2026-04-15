-- Persist agent pending write (tool + args) per chat session (HTTP is stateless vs in-memory LangGraph checkpoint).
BEGIN;
ALTER TABLE chat_sessions
    ADD COLUMN IF NOT EXISTS pending_agent_json JSONB;
COMMIT;
