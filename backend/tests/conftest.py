"""Hermetic test harness (ported from UniMatch).

Tests never touch the network, a real database, or secrets:
- the app module is imported fresh per test under a controlled test env;
- ``supabase.create_client`` is replaced with a guard that raises, so any
  code path that would reach a real DB fails loudly — tests fake the ``db``
  layer functions instead;
- per-test module state (client singleton, site cache, salt cache, geoip
  reader) is reset automatically.
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
    "JWT_SECRET": "test-jwt-secret-at-least-32-bytes-long",
    "ALLOWED_ORIGINS": "",
    "JWT_TTL_HOURS": "168",
}


def _forbidden_create_client(*_args, **_kwargs):
    raise RuntimeError(
        "Hermetic tests must not create a Supabase client — "
        "monkeypatch the db-layer function your code calls instead."
    )


@pytest.fixture(autouse=True)
def _hermetic(monkeypatch):
    """Forbid real Supabase clients and reset cached module state."""
    import db.client as db_client_module

    monkeypatch.setattr(db_client_module, "create_client", _forbidden_create_client)
    yield
    import db.client
    import db.sites
    from services import geoip, salt_cache

    db.client.reset_for_tests()
    db.sites.reset_for_tests()
    geoip.reset_for_tests()
    salt_cache.reset_for_tests()


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


@pytest.fixture()
def admin_headers(app_module):
    from services import auth as auth_service

    token = auth_service.create_token(app_module.app.state.settings)
    return {"Authorization": f"Bearer {token}"}
