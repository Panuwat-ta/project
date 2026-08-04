import pytest
from httpx import AsyncClient, ASGITransport
import io
from unittest.mock import AsyncMock, MagicMock
from app.main import app
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User

# Mocking database session
async def override_get_db():
    mock_session = MagicMock()
    
    async def mock_commit():
        pass
        
    async def mock_refresh(instance):
        import uuid
        from datetime import datetime, timezone
        instance.id = uuid.uuid4()
        instance.created_at = datetime.now(timezone.utc)
        
    mock_session.commit = AsyncMock(side_effect=mock_commit)
    mock_session.refresh = AsyncMock(side_effect=mock_refresh)
    yield mock_session

# Mocking authenticated user
async def override_get_current_user():
    user = User(id=1, email="test@scamguard.com", role="user")
    return user

app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_current_user] = override_get_current_user

@pytest.mark.asyncio
async def test_scan_upload():
    # Create a dummy image
    from PIL import Image
    image = Image.new('RGB', (100, 100))
    img_byte_arr = io.BytesIO()
    image.save(img_byte_arr, format='JPEG')
    img_bytes = img_byte_arr.getvalue()
    
    files = {'file': ('test.jpg', img_bytes, 'image/jpeg')}
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)
        
    assert response.status_code == 200
    data = response.json()
    assert "id" in data
    assert "visual_score" in data
    assert "total_risk_score" in data
    assert "risk_grade" in data

@pytest.mark.asyncio
async def test_scan_invalid_file_type():
    files = {'file': ('test.txt', b"dummy text", 'text/plain')}
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/api/v1/scan/", files=files)
        
    assert response.status_code == 400
    assert "Invalid file type" in response.json()["detail"]
