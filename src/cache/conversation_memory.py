"""
conversation_memory.py — In-session conversation history per session_id.

Each session keeps the last MAX_TURNS pairs (user + assistant).
Memory is in-process only — it resets when the server restarts.
"""
import threading
from collections import deque

MAX_TURNS = 8   # keep last 8 question/answer pairs = 16 messages


class ConversationMemory:
    def __init__(self, max_turns: int = MAX_TURNS):
        self._sessions: dict[str, deque] = {}
        self._lock = threading.Lock()
        self._max = max_turns * 2   # each turn = user + assistant

    def add(self, session_id: str, role: str, content: str) -> None:
        """Append a message to the session history."""
        with self._lock:
            if session_id not in self._sessions:
                self._sessions[session_id] = deque(maxlen=self._max)
            self._sessions[session_id].append({"role": role, "content": content})

    def get(self, session_id: str) -> list[dict]:
        """Return the history for a session (oldest first)."""
        with self._lock:
            return list(self._sessions.get(session_id, []))

    def clear(self, session_id: str) -> None:
        with self._lock:
            self._sessions.pop(session_id, None)

    def session_count(self) -> int:
        with self._lock:
            return len(self._sessions)


# Module-level singleton
conversation_memory = ConversationMemory()
