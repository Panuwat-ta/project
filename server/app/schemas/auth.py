from pydantic import BaseModel, EmailStr

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    system_consent: bool = True
    research_consent: bool = False

class LoginRequest(BaseModel):
    username: str  # email
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    role: str
    message: str = "User registered successfully"
