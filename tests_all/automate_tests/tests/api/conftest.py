"""API conftest"""
import pytest
from helpers.api_client import get_client, api_url
from helpers.auth_helper import register_and_login

@pytest.fixture
async def client():
    async with get_client() as c:
        yield c

@pytest.fixture
async def auth_user():
    return await register_and_login()

@pytest.fixture
async def auth_token(auth_user):
    return auth_user["token"]

@pytest.fixture
async def auth_headers(auth_token):
    return {"Authorization": f"Bearer {auth_token}"}
