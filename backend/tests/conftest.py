"""Hermetic test harness (ported from UniMatch).

Tests never touch the network, a real database, or secrets: the app module is
imported fresh per test with a controlled test environment. When supabase-py
and aiohttp land (M1), this file also grows the Forbidden* fakes that raise on
any real DB/HTTP attempt, keeping CI secret-free.
"""

from __future__ import annotations

import importlib
import os
import sys

import pytest

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

TEST_ENV = {
    "APP_ENV": "test",
    "SUPABASE_URL": "https://tests.supabase.co",
    "SUPABASE_SERVICE_ROLE_KEY": "test-key",
    "ADMIN_PASSWORD": "test-password",
    "JWT_SECRET": "test-jwt-secret",
    "ALLOWED_ORIGINS": "",
    "JWT_TTL_HOURS": "168",
}


@pytest.fixture()
def app_module(monkeypatch):
    """Import ``main`` fresh under the test environment."""
    for key, value in TEST_ENV.items():
        monkeypatch.setenv(key, value)
    for name in ("main", "config"):
        sys.modules.pop(name, None)
    module = importlib.import_module("main")
    yield module
    for name in ("main", "config"):
        sys.modules.pop(name, None)


@pytest.fixture()
def client(app_module):
    from fastapi.testclient import TestClient

    return TestClient(app_module.app)
