from typing import Literal
from pydantic import BaseModel, EmailStr, Field, HttpUrl

class RegisterIn(BaseModel):
    username: str = Field(min_length=3, max_length=30, pattern=r'^[a-zA-Z0-9_]+$')
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class PostIn(BaseModel):
    content: str = Field(min_length=1, max_length=1500)

class CommentIn(BaseModel):
    content: str = Field(min_length=1, max_length=700)

class ReactionIn(BaseModel):
    kind: Literal['like', 'love', 'haha', 'wow', 'sad', 'angry'] | None = None

class CartItemIn(BaseModel):
    product_id: int = Field(gt=0)
    quantity: int = Field(ge=1, le=20)

class OrderIn(BaseModel):
    items: list[CartItemIn] = Field(min_length=1, max_length=30)

class LoreIn(BaseModel):
    title: str = Field(min_length=3, max_length=160)
    summary: str = Field(min_length=5, max_length=500)
    body: str = Field(min_length=10)
    position: int = 0

class ProductIn(BaseModel):
    name: str = Field(min_length=3, max_length=160)
    character: str = Field(min_length=2, max_length=60)
    description: str
    price: float = Field(gt=0)
    stock: int = Field(ge=0)
    official_verified: bool = False
    active: bool = True

class EpisodeIn(BaseModel):
    title: str = Field(min_length=4, max_length=160)
    description: str = Field(min_length=10)
    video_url: HttpUrl
