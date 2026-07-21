import pytest


@pytest.fixture()
def recorder(monkeypatch, app_module):
    import db.stats as db_stats

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
        return 3

    monkeypatch.setattr(db_stats, "timeseries", fake_timeseries)
    monkeypatch.setattr(db_stats, "breakdown", fake_breakdown)
    monkeypatch.setattr(db_stats, "summary", fake_summary)
    monkeypatch.setattr(db_stats, "live", fake_live)
    return calls


BASE = "/sites/site-1/stats"


def test_timeseries_passthrough(client, admin_headers, recorder):
    resp = client.get(
        f"{BASE}/timeseries?from=2026-07-01&to=2026-07-20&bucket=day",
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert recorder["timeseries"] == ("site-1", "2026-07-01", "2026-07-20", "day")
    assert resp.json()[0]["pageviews"] == 10


def test_timeseries_validation(client, admin_headers, recorder):
    q = f"{BASE}/timeseries"
    assert client.get(f"{q}?from=2026-07-01&to=2026-07-20&bucket=hour",
                      headers=admin_headers).status_code == 422
    assert client.get(f"{q}?from=2026-07-20&to=2026-07-01",
                      headers=admin_headers).status_code == 422
    assert client.get(f"{q}?from=2020-01-01&to=2026-07-20",
                      headers=admin_headers).status_code == 422
    assert client.get(f"{q}?from=notadate&to=2026-07-20",
                      headers=admin_headers).status_code == 422


def test_breakdown_passthrough_and_validation(client, admin_headers, recorder):
    resp = client.get(
        f"{BASE}/breakdown?from=2026-07-01&to=2026-07-20&dim=page&limit=5",
        headers=admin_headers,
    )
    assert resp.status_code == 200
    assert recorder["breakdown"] == ("site-1", "2026-07-01", "2026-07-20", "page", 5)

    q = f"{BASE}/breakdown?from=2026-07-01&to=2026-07-20"
    assert client.get(f"{q}&dim=os", headers=admin_headers).status_code == 422
    assert client.get(f"{q}&dim=page&limit=0", headers=admin_headers).status_code == 422
    assert client.get(f"{q}&dim=page&limit=101", headers=admin_headers).status_code == 422


def test_summary_and_live(client, admin_headers, recorder):
    resp = client.get(f"{BASE}/summary?from=2026-07-01&to=2026-07-20",
                      headers=admin_headers)
    assert resp.status_code == 200
    assert resp.json() == {"pageviews": 10, "visitors": 4}

    resp = client.get(f"{BASE}/live", headers=admin_headers)
    assert resp.status_code == 200
    assert resp.json() == {"online": 3}
    assert recorder["live"] == "site-1"


def test_stats_require_auth(client, recorder):
    assert client.get(f"{BASE}/live").status_code == 401
