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
