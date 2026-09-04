from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.db import models
from pydantic import BaseModel
from app.core.security import get_current_user

router = APIRouter()

class FCMTokenRequest(BaseModel):
    fcm_token: str

@router.post("/fcm-token")
async def update_fcm_token(
    request: FCMTokenRequest,
    current_user: str = Depends(get_current_user), # username string
    db: Session = Depends(get_db)
):
    # Since we are currently using mock users in auth.py, we need to handle 
    # the case where the user might not exist in the DB yet, or we can just 
    # print it out. If a user system is implemented, this is how it would save.
    
    # Try to find the user
    user = db.query(models.User).filter(models.User.id == 1).first() # Forcing to user id 1 since auth is mocked
    
    if not user:
        # Create a mock user if one doesn't exist just to store the token
        user = models.User(preferred_language="en", fcm_token=request.fcm_token)
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.fcm_token = request.fcm_token
        db.commit()
        
    return {"message": "FCM token updated successfully"}
