from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from app.core.security import create_access_token, get_password_hash, verify_password
from datetime import timedelta
from app.core.security import ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter()

# Note: In a real app, users would be created and stored in the database.
# Since we didn't add a password column to the User model, we'll mock a default user
# for the sake of the architectural requirement.

MOCK_USER = {
    "username": "user",
    "password_hash": get_password_hash("password") # In prod, this is in the DB
}

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    # Mock user validation
    if form_data.username != MOCK_USER["username"] or not verify_password(form_data.password, MOCK_USER["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": form_data.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

from pydantic import BaseModel
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from app.core.config import settings

class GoogleAuthRequest(BaseModel):
    id_token: str | None = None
    access_token: str | None = None

import httpx

@router.post("/google")
async def google_login(request: GoogleAuthRequest):
    try:
        email = None
        
        if request.id_token:
            # Verify the ID token with Google
            idinfo = id_token.verify_oauth2_token(
                request.id_token, google_requests.Request(), settings.GOOGLE_CLIENT_ID
            )
            email = idinfo.get("email")
            
        elif request.access_token:
            # Verify the Access token with Google UserInfo endpoint
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://www.googleapis.com/oauth2/v3/userinfo",
                    headers={"Authorization": f"Bearer {request.access_token}"}
                )
                if response.status_code != 200:
                    raise ValueError(f"Invalid access token: {response.text}")
                userinfo = response.json()
                email = userinfo.get("email")
        else:
            raise ValueError("Must provide either id_token or access_token")

        if not email:
            raise ValueError("No email found in Google token response")

        # In a real app, you'd find or create the user in the database here based on email
        username = email.split('@')[0] # Mock username generation from email

        # Create our own JWT access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": username}, expires_delta=access_token_expires
        )
        return {"access_token": access_token, "token_type": "bearer"}

    except ValueError as e:
        # Invalid token
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
