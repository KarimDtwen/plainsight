import pytest


@pytest.fixture()
def rollup_recorder(monkeypatch, app_module):
    import db.stats as db_stats

    days = []
    monkeypatch.setattr(db_stats, "rollup_day", lambda s, day: days.append(day))
    return days


def test_manual_rollup(client, admin_headers, rollup_recorder):
    resp = client.post("/admin/rollup?day=2026-07-20", headers=admin_headers)
    assert resp.status_code == 200
    assert resp.json() == {"ok": True, "day": "2026-07-20"}
    assert rollup_recorder == ["2026-07-20"]


def test_rollup_validates_date(client, admin_headers, rollup_recorder):
    assert client.post("/admin/rollup?day=yesterday",
                       headers=admin_headers).status_code == 422
    assert rollup_recorder == []


def test_rollup_requires_auth(client, rollup_recorder):
    assert client.post("/admin/rollup?day=2026-07-20").status_code == 401
