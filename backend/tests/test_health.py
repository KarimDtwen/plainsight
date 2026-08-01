def test_app_imports_hermetically(app_module):
    # Importing main under the test env must construct the app without any
    # network, database, or secret access.
    assert app_module.app.title == "Plainsight"


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    # No geoip database is bundled in the hermetic test env.
    assert body["geoip"] is False
    assert "no *.mmdb file" in body["geoip_detail"]
