from __future__ import annotations

from config import Settings
from db import client as db_client


def insert_event(settings: Settings, row: dict) -> None:
    db_client.get_client(settings).table("events").insert(row).execute()
