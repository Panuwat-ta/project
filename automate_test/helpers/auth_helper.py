"""Auth helpers — register / login / token (ตรง spec จริง)"""
import uuid
from helpers.api_client import get_client, api_url

async def register_and_login(email: str = None, password: str = None, full_name: str = "Auto Tester"):
    """สมัคร user ใหม่แล้ว login คืน {email, password, token, user_id}"""
    if email is None:
        email = f"auto_{uuid.uuid4().hex[:8]}@example.com"
    if password is None:
        password = "Test1234!@#"
    async with get_client() as client:
        # register — spec ต้อง full_name + consents
        await client.post(api_url("/auth/register"), json={
            "email": email,
            "password": password,
            "full_name": full_name,
            "system_consent": True,
            "research_consent": False,
        })
        # login — ใช้ OAuth2PasswordRequestForm = form-encoded username/password
        r = await client.post(api_url("/auth/login"), data={
            "username": email,
            "password": password,
        }, headers={"Content-Type": "application/x-www-form-urlencoded"})
        r.raise_for_status()
        data = r.json()
        token = data.get("access_token") or data.get("token")
        user_id = (data.get("user") or {}).get("id")
        return {"email": email, "password": password, "token": token, "user_id": user_id, "raw": data}

async def login_admin():
    from config.settings import TEST_ADMIN_EMAIL, TEST_ADMIN_PASSWORD
    async with get_client() as client:
        r = await client.post(api_url("/auth/login"), data={
            "username": TEST_ADMIN_EMAIL,
            "password": TEST_ADMIN_PASSWORD,
        }, headers={"Content-Type": "application/x-www-form-urlencoded"})
        r.raise_for_status()
        data = r.json()
        token = data.get("access_token") or data.get("token")
        return token

def auth_header(token: str):
    return {"Authorization": f"Bearer {token}"}
