import os
from datetime import datetime, timedelta, timezone
import jwt
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from .database import get_db
from .models import User

JWT_SECRET = os.getenv('JWT_SECRET', '')
if len(JWT_SECRET) < 32 or JWT_SECRET.startswith('CAMBIA_'):
    raise RuntimeError('Configura JWT_SECRET con 32 o más caracteres aleatorios en backend/.env')

pwd = PasswordHash.recommended()
bearer = HTTPBearer(auto_error=False)
TOKEN_MINUTES = int(os.getenv('ACCESS_TOKEN_MINUTES', '120'))

def hash_password(value: str) -> str:
    return pwd.hash(value)

def valid_password(value: str, encoded: str) -> bool:
    return pwd.verify(value, encoded)

def create_token(user_id: int) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode({'sub': str(user_id), 'iat': now, 'exp': now + timedelta(minutes=TOKEN_MINUTES)}, JWT_SECRET, algorithm='HS256')

def current_user(credentials: HTTPAuthorizationCredentials | None = Depends(bearer), db: Session = Depends(get_db)) -> User:
    unauthorized = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail='Sesión vencida o no válida', headers={'WWW-Authenticate': 'Bearer'})
    if credentials is None:
        raise unauthorized
    try:
        claims = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=['HS256'])
        user_id = int(claims['sub'])
    except (InvalidTokenError, ValueError, KeyError, TypeError):
        raise unauthorized
    user = db.get(User, user_id)
    if user is None:
        raise unauthorized
    return user

def admin_user(user: User = Depends(current_user)) -> User:
    if user.role != 'admin':
        raise HTTPException(status_code=403, detail='Solo administradores')
    return user
