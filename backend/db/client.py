"""Lazy Supabase client (supabase-py, no ORM).

Created on first use, never at import — imports stay hermetic and tests can
forbid client creation outright (see tests/conftest.py)."""

from __future__ import annotations

from supabase import Client, create_client

from config import Settings

_client: Client | None = None


def get_client(settings: Settings) -> Client:
    global _client
    if _client is None:
        _client = create_client(settings.supabase_url, settings.supabase_key)
    return _client


def reset_for_tests() -> None:
    global _client
    _client = None
