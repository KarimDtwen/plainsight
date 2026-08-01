def test_app_imports_hermetically(app_module):
    # Importing main under the test env must construct the app without any
    # network, database, or secret access.
    assert app_module.app.title == "Plainsight"


def test_health_endpoint(client, tmp_path, monkeypatch):
    # Isolated from whatever backend/geoip/ happens to hold on the machine
    # running the tests (e.g. a real mmdb fetched locally to verify a fix) —
    # same pattern as test_geoip.py's own GEOIP_DIR monkeypatches.
    from services import geoip

    monkeypatch.setattr(geoip, "GEOIP_DIR", str(tmp_path))
    geoip.reset_for_tests()

    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["geoip"] is False
    assert "no *.mmdb file" in body["geoip_detail"]
