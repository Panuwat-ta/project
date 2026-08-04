import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import AsyncMock, MagicMock
from app.main import app
from app.core.database import get_db
from app.models.user import User

# We can mock hash/verify functions to avoid passlib bcrypt truncation bug in tests
import app.api.v1.auth as auth_router
auth_router.hash_password = lambda pw: "mocked_hash"
auth_router.verify_password = lambda pw, hsh: pw == "password123" and hsh == "mocked_hash"

# Mocking database session
async def override_get_db():
    mock_session = MagicMock()
    
    async def mock_commit():
        pass
        
    async def mock_refresh(instance):
        instance.id = 1
        
    # Mock for execute (used in login and register)
    async def mock_execute(statement):
        # We need a mock result object that has .scalars().first()
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        
        # We want register to pass (no existing user), and login to pass (existing user)
        # statement is a Select object.
        # It's tricky to inspect, so we compile it with literal binds
        stmt_str = str(statement.compile(compile_kwargs={"literal_binds": True}))
        
        user = None
        if "test@scamguard.com" in stmt_str:
            user = User(
                id=1, 
                email="test@scamguard.com", 
                hashed_password="mocked_hash",
                role="user",
                full_name="Test User"
            )
            
        mock_scalars.first.return_value = user
        mock_result.scalars.return_value = mock_scalars
        return mock_result
        
    mock_session.commit = AsyncMock(side_effect=mock_commit)
    mock_session.refresh = AsyncMock(side_effect=mock_refresh)
    mock_session.execute = AsyncMock(side_effect=mock_execute)
    
    yield mock_session

app.dependency_overrides[get_db] = override_get_db

@pytest.mark.asyncio
async def test_register():
    payload = {
        "email": "newuser@scamguard.com",
        "password": "password123",
        "full_name": "New User",
        "system_consent": True,
        "research_consent": False
    }
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/auth/register", json=payload)
        
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "newuser@scamguard.com"
    assert "id" in data

@pytest.mark.asyncio
async def test_login():
    payload = {
        "username": "test@scamguard.com",
        "password": "password123"
    }
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/auth/login", data=payload)
        
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
