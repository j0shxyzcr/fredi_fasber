"""Uso local: python -m scripts.promote_admin nombre_de_usuario"""
import sys
from sqlalchemy import select
from app.database import SessionLocal
from app.models import User

if len(sys.argv) != 2:
    raise SystemExit('Uso: python -m scripts.promote_admin NOMBRE_USUARIO')
with SessionLocal() as db:
    user = db.scalar(select(User).where(User.username == sys.argv[1]))
    if not user:
        raise SystemExit('Usuario no encontrado. Regístralo primero desde Flutter.')
    user.role = 'admin'
    db.commit()
    print('Administrador activado:', user.username)
