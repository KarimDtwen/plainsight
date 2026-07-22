import pytest

SITE = {"id": "site-1", "site_key": "deadbeef", "name": "My Site",
        "domain": "example.com", "share_slug": "the-slug"}

BASE = "/public/the-slug"


@pytest.fixture()
def fake_public(monkeypatch, app_module):
    import db.sites as db_sites
    import db.stats as db_stats

    def get_by_slug(settings, slug):
        return SITE if slug == "the-slug" else None

    calls = {}

    def fake_timeseries(s, site, f, t, b):
        calls["timeseries"] = (site, f, t, b)
        return [{"bucket": "2026-07-20", "pageviews": 10, "visitors": 4}]

    def fake_breakdown(s, site, f, t, d, lim):
        calls["breakdown"] = (site, f, t, d, lim)
        return [{"value": "/", "pageviews": 5, "visitors": 3}]

    def fake_summary(s, site, f, t):
        calls["summary"] = (site, f, t)
        return {"pageviews": 10, "visitors": 4}

    def fake_live(s, site):
        calls["live"] = site
        return 2

    monkeypatch.setattr(db_sites, "get_site_by_slug", get_by_slug)
    monkeypatch.setattr(db_stats, "timeseries", fake_timeseries)
    monkeypatch.setattr(db_stats, "breakdown", fake_breakdown)
    monkeypatch.setattr(db_stats, "summary", fake_summary)
    monkeypatch.setattr(db_stats, "live", fake_live)
    return calls


def test_public_site_info(client, fake_public):
    resp = client.get(f"{BASE}/site")
    assert resp.status_code == 200
    assert resp.json() == {"name": "My Site", "domain": "example.com"}


def test_public_stats_no_auth_required(client, fake_public):
    resp = client.get(f"{BASE}/stats/timeseries?from=2026-07-01&to=2026-07-20&bucket=day")
    assert resp.status_code == 200
    assert fake_public["timeseries"] == ("site-1", "2026-07-01", "2026-07-20", "day")

    resp = client.get(f"{BASE}/stats/breakdown?from=2026-07-01&to=2026-07-20&dim=page")
    assert resp.status_code == 200
    assert fake_public["breakdown"][0] == "site-1"

    resp = client.get(f"{BASE}/stats/summary?from=2026-07-01&to=2026-07-20")
    assert resp.status_code == 200
    assert resp.json() == {"pageviews": 10, "visitors": 4}

    resp = client.get(f"{BASE}/stats/live")
    assert resp.status_code == 200
    assert resp.json() == {"online": 2}


def test_unknown_slug_404s_before_any_query(client, fake_public):
    resp = client.get("/public/nope/stats/live")
    assert resp.status_code == 404
    assert "live" not in fake_public

    resp = client.get("/public/nope/site")
    assert resp.status_code == 404


def test_public_stats_validation(client, fake_public):
    q = f"{BASE}/stats/timeseries?from=2026-07-01&to=2026-07-20"
    assert client.get(f"{q}&bucket=hour").status_code == 422

    q = f"{BASE}/stats/breakdown?from=2026-07-01&to=2026-07-20"
    assert client.get(f"{q}&dim=os").status_code == 422

    assert client.get(f"{BASE}/stats/summary?from=2026-07-20&to=2026-07-01").status_code == 422
