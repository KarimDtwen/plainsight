import time


def test_login_returns_verifiable_token(client, app_module):
    resp = client.post("/auth/login", json={"password": "test-password"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["expires_in_hours"] == 168

    from services import auth as auth_service

    assert auth_service.verify_token(app_module.app.state.settings, body["token"])


def test_login_wrong_password(client):
    assert client.post("/auth/login", json={"password": "nope"}).status_code == 401


def test_protected_route_requires_token(client):
    assert client.get("/sites").status_code == 401


def test_protected_route_rejects_garbage_token(client):
    resp = client.get("/sites", headers={"Authorization": "Bearer not.a.jwt"})
    assert resp.status_code == 401


def test_expired_token_rejected(client, app_module):
    from services import auth as auth_service

    settings = app_module.app.state.settings
    expired = auth_service.create_token(
        settings, now=time.time() - (settings.jwt_ttl_hours + 1) * 3600
    )
    resp = client.get("/sites", headers={"Authorization": f"Bearer {expired}"})
    assert resp.status_code == 401
