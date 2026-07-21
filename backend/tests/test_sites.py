import pytest

ROW = {"id": "site-1", "site_key": "deadbeef", "name": "My Site",
       "domain": "example.com", "share_slug": None}


@pytest.fixture()
def fake_sites(monkeypatch, app_module):
    import db.sites as db_sites

    calls = {"created": [], "deleted": []}

    def create(settings, name, domain):
        calls["created"].append((name, domain))
        return dict(ROW, name=name, domain=domain)

    monkeypatch.setattr(db_sites, "list_sites", lambda s: [ROW])
    monkeypatch.setattr(db_sites, "create_site", create)
    monkeypatch.setattr(db_sites, "delete_site",
                        lambda s, site_id: calls["deleted"].append(site_id))
    return calls


def test_list_sites(client, admin_headers, fake_sites):
    resp = client.get("/sites", headers=admin_headers)
    assert resp.status_code == 200
    assert resp.json() == [ROW]


def test_create_site_normalizes_domain_and_returns_snippet(
    client, admin_headers, fake_sites
):
    resp = client.post(
        "/sites",
        headers=admin_headers,
        json={"name": " Demo ", "domain": "HTTPS://Example.COM/some/path"},
    )
    assert resp.status_code == 201
    assert fake_sites["created"] == [("Demo", "example.com")]
    snippet = resp.json()["install_snippet"]
    assert 'data-site="deadbeef"' in snippet
    assert "/js/script.js" in snippet


def test_create_site_rejects_non_hostname(client, admin_headers, fake_sites):
    resp = client.post(
        "/sites", headers=admin_headers, json={"name": "x", "domain": "nodots"}
    )
    assert resp.status_code == 422
    assert fake_sites["created"] == []


def test_delete_site(client, admin_headers, fake_sites):
    resp = client.delete("/sites/site-1", headers=admin_headers)
    assert resp.status_code == 204
    assert fake_sites["deleted"] == ["site-1"]
