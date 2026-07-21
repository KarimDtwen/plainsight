import json

import pytest

CHROME = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
SITE = {"id": "11111111-2222-3333-4444-555555555555", "domain": "example.com",
        "site_key": "abcd1234", "name": "Example"}


@pytest.fixture()
def fake_db(monkeypatch, app_module):
    """Fake the db layer around /collect and record inserts."""
    import db.events as db_events
    import db.salts as db_salts
    import db.sites as db_sites

    inserted = []
    monkeypatch.setattr(db_sites, "get_site_by_key",
                        lambda settings, key: SITE if key == SITE["site_key"] else None)
    monkeypatch.setattr(db_salts, "get_daily_salt", lambda settings: "test-salt")
    monkeypatch.setattr(db_events, "insert_event",
                        lambda settings, row: inserted.append(row))
    return inserted


def _post(client, body, ua=CHROME, **headers):
    return client.post(
        "/collect",
        content=body if isinstance(body, (str, bytes)) else json.dumps(body),
        headers={"User-Agent": ua, "Content-Type": "text/plain", **headers},
    )


def test_valid_event_inserted(client, fake_db):
    resp = _post(client, {"s": "abcd1234", "u": "/pricing?x=1", "r": "https://www.google.com/search", "w": 1440})
    assert resp.status_code == 202
    assert resp.headers["access-control-allow-origin"] == "*"
    assert len(fake_db) == 1
    row = fake_db[0]
    assert row["site_id"] == SITE["id"]
    assert row["path"] == "/pricing?x=1"
    assert row["referrer_host"] == "www.google.com"
    assert row["device"] == "desktop"
    assert row["browser"] == "chrome"
    assert len(row["visitor_hash"]) == 32
    assert "ip" not in row and "user_agent" not in row  # privacy invariant


def test_unknown_site_silent_202(client, fake_db):
    resp = _post(client, {"s": "nope", "u": "/"})
    assert resp.status_code == 202
    assert fake_db == []


def test_bot_dropped(client, fake_db):
    resp = _post(client, {"s": "abcd1234", "u": "/"}, ua="Googlebot/2.1")
    assert resp.status_code == 202
    assert fake_db == []


def test_malformed_and_oversized_bodies(client, fake_db):
    assert _post(client, "{not json").status_code == 202
    assert _post(client, json.dumps(["a", "list"])).status_code == 202
    assert _post(client, "x" * 5000).status_code == 202
    assert fake_db == []


def test_missing_site_key(client, fake_db):
    assert _post(client, {"u": "/"}).status_code == 202
    assert fake_db == []


def test_self_referral_stored_as_direct(client, fake_db):
    _post(client, {"s": "abcd1234", "u": "/", "r": "https://example.com/other"})
    assert fake_db[0]["referrer_host"] == ""


def test_path_normalized(client, fake_db):
    _post(client, {"s": "abcd1234", "u": "pricing"})
    assert fake_db[0]["path"] == "/pricing"


def test_db_failure_still_202(client, monkeypatch, app_module):
    import db.sites as db_sites

    def boom(settings, key):
        raise RuntimeError("db down")

    monkeypatch.setattr(db_sites, "get_site_by_key", boom)
    assert _post(client, {"s": "abcd1234", "u": "/"}).status_code == 202


def test_production_origin_mismatch_dropped(app_module, monkeypatch):
    from fastapi.testclient import TestClient

    import db.events as db_events
    import db.salts as db_salts
    import db.sites as db_sites
    from config import Settings

    prod = Settings.from_env({
        "APP_ENV": "production",
        "SUPABASE_URL": "https://example.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "k",
        "ADMIN_PASSWORD": "p",
        "JWT_SECRET": "s",
        "ALLOWED_ORIGINS": "https://dash.example.com",
    })
    inserted = []
    monkeypatch.setattr(db_sites, "get_site_by_key", lambda s, k: SITE)
    monkeypatch.setattr(db_salts, "get_daily_salt", lambda s: "salt")
    monkeypatch.setattr(db_events, "insert_event", lambda s, r: inserted.append(r))

    prod_client = TestClient(app_module.create_app(prod))
    # Mismatched Origin → dropped.
    resp = _post(prod_client, {"s": "abcd1234", "u": "/"}, Origin="https://evil.io")
    assert resp.status_code == 202 and inserted == []
    # Matching Origin → inserted.
    _post(prod_client, {"s": "abcd1234", "u": "/"}, Origin="https://example.com")
    # Missing Origin → allowed (soft check).
    _post(prod_client, {"s": "abcd1234", "u": "/"})
    assert len(inserted) == 2


def test_acao_star_survives_global_cors_middleware_for_real_customer_sites(
    app_module, monkeypatch
):
    """The whole point of /collect: a real tracked site's Origin is never the
    dashboard's own origin, so Starlette's CORSMiddleware (allow_origins =
    dashboard only, no wildcard) must leave our explicit `ACAO: *` untouched —
    it only overwrites the header when the request Origin matches its own
    allow-list/regex, which a genuine customer domain never will in prod."""
    from fastapi.testclient import TestClient

    import db.events as db_events
    import db.salts as db_salts
    import db.sites as db_sites
    from config import Settings

    prod = Settings.from_env({
        "APP_ENV": "production",
        "SUPABASE_URL": "https://example.supabase.co",
        "SUPABASE_SERVICE_ROLE_KEY": "k",
        "ADMIN_PASSWORD": "p",
        "JWT_SECRET": "s",
        "ALLOWED_ORIGINS": "https://dash.example.com",
    })
    monkeypatch.setattr(db_sites, "get_site_by_key", lambda s, k: SITE)
    monkeypatch.setattr(db_salts, "get_daily_salt", lambda s: "salt")
    monkeypatch.setattr(db_events, "insert_event", lambda s, r: None)

    prod_client = TestClient(app_module.create_app(prod))
    resp = _post(
        prod_client, {"s": "abcd1234", "u": "/"}, Origin="https://example.com"
    )
    assert resp.status_code == 202
    assert resp.headers["access-control-allow-origin"] == "*"
