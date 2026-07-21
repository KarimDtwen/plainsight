"""Visitor identity without cookies or stored PII.

``visitor_hash = sha256(daily_salt | site_id | ip | user_agent)`` — computed
in-process at ingest time. The IP and raw user-agent are inputs only and are
never persisted; the salt rotates daily and is destroyed after 2 days
(``purge_old_salts``), so hashes cannot be re-identified even with a DB dump.
"""

from __future__ import annotations

import hashlib


def visitor_hash(daily_salt: str, site_id: str, ip: str, user_agent: str) -> str:
    material = f"{daily_salt}|{site_id}|{ip}|{user_agent}".encode()
    return hashlib.sha256(material).hexdigest()[:32]
