import os
from contextlib import asynccontextmanager
from decimal import Decimal
import httpx
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from .database import Base, SessionLocal, engine, get_db
from .models import Comment, Episode, Game, Lore, Order, OrderItem, Post, Product, Reaction, User
from .schemas import CommentIn, EpisodeIn, LoginIn, LoreIn, OrderIn, PostIn, ProductIn, ReactionIn, RegisterIn
from .security import admin_user, create_token, current_user, hash_password, valid_password
from .seed import seed_if_empty

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        seed_if_empty(db)
    yield

app = FastAPI(title='Fazbear Archives API', version='1.0.0', description='Proyecto escolar no oficial de FNAF', lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=['http://localhost:8080', 'http://127.0.0.1:8080'], allow_credentials=False, allow_methods=['GET','POST'], allow_headers=['Authorization','Content-Type'])

def user_json(user: User) -> dict:
    return {'id': user.id, 'username': user.username, 'email': user.email, 'role': user.role}

def post_json(post: Post, db: Session, user_id: int) -> dict:
    rows = db.execute(select(Reaction.kind, func.count(Reaction.id)).where(Reaction.post_id == post.id).group_by(Reaction.kind)).all()
    my_reaction = db.scalar(select(Reaction.kind).where(Reaction.post_id == post.id, Reaction.user_id == user_id))
    count = db.scalar(select(func.count(Comment.id)).where(Comment.post_id == post.id)) or 0
    return {'id': post.id, 'author': post.author.username, 'author_id': post.author_id, 'content': post.content,
            'created_at': post.created_at.isoformat() + 'Z', 'reactions': {kind: n for kind, n in rows},
            'my_reaction': my_reaction, 'comments_count': count}

@app.get('/health')
def health():
    return {'status': 'ok'}

@app.post('/auth/register', status_code=201)
def register(body: RegisterIn, db: Session = Depends(get_db)):
    email = str(body.email).lower()
    if db.scalar(select(User).where((User.email == email) | (User.username == body.username))):
        raise HTTPException(status_code=409, detail='El usuario o correo ya existe')
    user = User(username=body.username, email=email, password_hash=hash_password(body.password))
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail='El usuario o correo ya existe')
    db.refresh(user)
    return {'access_token': create_token(user.id), 'token_type': 'bearer', 'user': user_json(user)}

@app.post('/auth/login')
def login(body: LoginIn, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == str(body.email).lower()))
    if user is None or not valid_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail='Correo o contraseña incorrectos')
    return {'access_token': create_token(user.id), 'token_type': 'bearer', 'user': user_json(user)}

@app.get('/auth/me')
def me(user: User = Depends(current_user)):
    return user_json(user)

@app.get('/lore')
def lore(db: Session = Depends(get_db)):
    entries = db.scalars(select(Lore).order_by(Lore.position)).all()
    return [{'id': e.id, 'title': e.title, 'summary': e.summary, 'body': e.body, 'position': e.position} for e in entries]

@app.post('/admin/lore', status_code=201)
def add_lore(body: LoreIn, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    if db.scalar(select(Lore).where(Lore.title == body.title)):
        raise HTTPException(status_code=409, detail='Ya existe')
    item = Lore(**body.model_dump())
    db.add(item)
    db.commit()
    return {'id': item.id}

@app.get('/episodes')
def episodes(db: Session = Depends(get_db)):
    items = db.scalars(select(Episode).order_by(Episode.published_at.desc())).all()
    return [{'id': e.id, 'title': e.title, 'description': e.description, 'video_url': e.video_url,
             'published_at': e.published_at.isoformat() + 'Z'} for e in items]

@app.post('/admin/episodes', status_code=201)
def add_episode(body: EpisodeIn, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    if body.video_url.host not in ('youtube.com', 'www.youtube.com', 'youtu.be', 'www.youtu.be'):
        raise HTTPException(422, detail='Usa un enlace HTTPS de YouTube')
    if db.scalar(select(Episode).where(Episode.title == body.title)):
        raise HTTPException(409, detail='Ya existe un episodio con ese título')
    item = Episode(title=body.title, description=body.description, video_url=str(body.video_url))
    db.add(item)
    db.commit()
    return {'id': item.id}

@app.get('/games')
def games(db: Session = Depends(get_db)):
    items = db.scalars(select(Game).order_by(Game.year, Game.id)).all()
    return [{'id': e.id, 'name': e.name, 'year': e.year, 'description': e.description} for e in items]

@app.get('/posts')
def posts(db: Session = Depends(get_db), user: User = Depends(current_user)):
    items = db.scalars(select(Post).order_by(Post.created_at.desc(), Post.id.desc()).limit(100)).all()
    return [post_json(p, db, user.id) for p in items]

@app.post('/posts', status_code=201)
def make_post(body: PostIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if not body.content.strip():
        raise HTTPException(422, detail='Escribe una publicación')
    post = Post(author_id=user.id, content=body.content.strip())
    db.add(post)
    db.commit()
    db.refresh(post)
    return post_json(post, db, user.id)

@app.post('/posts/{post_id}/reactions')
def set_reaction(post_id: int, body: ReactionIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if db.get(Post, post_id) is None:
        raise HTTPException(404, detail='Publicación no encontrada')
    reaction = db.scalar(select(Reaction).where(Reaction.post_id == post_id, Reaction.user_id == user.id))
    if body.kind is None:
        if reaction: db.delete(reaction)
    elif reaction:
        reaction.kind = body.kind
    else:
        db.add(Reaction(post_id=post_id, user_id=user.id, kind=body.kind))
    db.commit()
    return post_json(db.get(Post, post_id), db, user.id)

@app.get('/posts/{post_id}/comments')
def get_comments(post_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if db.get(Post, post_id) is None:
        raise HTTPException(404, detail='Publicación no encontrada')
    items = db.scalars(select(Comment).where(Comment.post_id == post_id).order_by(Comment.created_at)).all()
    return [{'id': c.id, 'author': c.author.username, 'content': c.content, 'created_at': c.created_at.isoformat() + 'Z'} for c in items]

@app.post('/posts/{post_id}/comments', status_code=201)
def make_comment(post_id: int, body: CommentIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    if db.get(Post, post_id) is None:
        raise HTTPException(404, detail='Publicación no encontrada')
    if not body.content.strip():
        raise HTTPException(422, detail='Escribe un comentario')
    c = Comment(post_id=post_id, author_id=user.id, content=body.content.strip())
    db.add(c)
    db.commit()
    db.refresh(c)
    return {'id': c.id, 'author': user.username, 'content': c.content, 'created_at': c.created_at.isoformat() + 'Z'}

@app.get('/products')
def products(db: Session = Depends(get_db)):
    items = db.scalars(select(Product).where(Product.active.is_(True)).order_by(Product.id)).all()
    return [{'id': p.id, 'name': p.name, 'character': p.character, 'description': p.description,
             'price': float(p.price), 'stock': p.stock, 'official_verified': p.official_verified} for p in items]

@app.post('/admin/products', status_code=201)
def add_product(body: ProductIn, db: Session = Depends(get_db), admin: User = Depends(admin_user)):
    if db.scalar(select(Product).where(Product.name == body.name)):
        raise HTTPException(409, detail='Nombre ya registrado')
    p = Product(**body.model_dump())
    db.add(p)
    db.commit()
    return {'id': p.id}

@app.post('/orders', status_code=201)
def create_order(body: OrderIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    # El cálculo del total se realiza exclusivamente en el servidor.
    ids = [item.product_id for item in body.items]
    if len(set(ids)) != len(ids):
        raise HTTPException(422, detail='No dupliques productos en el pedido')
    prices = []
    for item in body.items:
        p = db.get(Product, item.product_id)
        if p is None or not p.active or item.quantity > p.stock:
            raise HTTPException(409, detail=f'Producto {item.product_id} inexistente o sin inventario suficiente')
        prices.append((p, item.quantity))
    total = sum((p.price * qty for p, qty in prices), Decimal('0.00'))
    order = Order(user_id=user.id, total=total, status='pending_payment')
    db.add(order)
    db.flush()
    for p, qty in prices:
        db.add(OrderItem(order_id=order.id, product_id=p.id, quantity=qty, unit_price=p.price))
    db.commit()
    db.refresh(order)
    return order_json(order)

def order_json(order: Order) -> dict:
    return {'id': order.id, 'total': float(order.total), 'status': order.status,
            'created_at': order.created_at.isoformat() + 'Z',
            'items': [{'name': i.product.name, 'quantity': i.quantity, 'unit_price': float(i.unit_price)} for i in order.items]}

@app.get('/orders')
def orders(db: Session = Depends(get_db), user: User = Depends(current_user)):
    rows = db.scalars(select(Order).where(Order.user_id == user.id).order_by(Order.id.desc())).all()
    return [order_json(e) for e in rows]

@app.post('/orders/{order_id}/checkout')
async def checkout(order_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    order = db.get(Order, order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(404, detail='Pedido no encontrado')
    if order.status != 'pending_payment':
        raise HTTPException(409, detail='El pedido ya no está pendiente')
    token = os.getenv('MP_ACCESS_TOKEN', '')
    if not token:
        raise HTTPException(503, detail='Mercado Pago no está configurado; el pedido quedó como demostración sin cobro')
    if any(not item.product.official_verified for item in order.items):
        raise HTTPException(409, detail='No se permite cobrar productos sin proveedor/licencia verificados')
    payload = {
        'items': [{'id': str(i.product_id), 'title': i.product.name, 'quantity': i.quantity,
                   'unit_price': float(i.unit_price), 'currency_id': 'MXN'} for i in order.items],
        'payer': {'email': user.email}, 'external_reference': str(order.id),
    }
    return_url = os.getenv('MP_RETURN_URL', '')
    if return_url:
        payload['back_urls'] = {'success': return_url, 'failure': return_url, 'pending': return_url}
    async with httpx.AsyncClient(timeout=15) as client:
        try:
            response = await client.post('https://api.mercadopago.com/checkout/preferences',
                         headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}, json=payload)
            response.raise_for_status()
            result = response.json()
        except (httpx.HTTPError, ValueError):
            raise HTTPException(502, detail='No se pudo crear el enlace de pago')
    order.payment_preference_id = str(result.get('id', ''))[:160]
    db.commit()
    if not result.get('init_point'):
        raise HTTPException(502, detail='Mercado Pago no devolvió enlace de pago')
    return {'url': result['init_point'], 'order_id': order.id}

@app.post('/orders/{order_id}/verify-payment')
async def verify_payment(order_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    order = db.get(Order, order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(404, detail='Pedido no encontrado')
    token = os.getenv('MP_ACCESS_TOKEN', '')
    if not token or not order.payment_preference_id:
        raise HTTPException(503, detail='El pedido aún no tiene un pago en línea configurado')
    async with httpx.AsyncClient(timeout=15) as client:
        try:
            response = await client.get('https://api.mercadopago.com/v1/payments/search',
                params={'external_reference': str(order.id)}, headers={'Authorization': f'Bearer {token}'})
            response.raise_for_status()
            payments = response.json().get('results', [])
        except (httpx.HTTPError, ValueError):
            raise HTTPException(502, detail='No se pudo verificar el pago')
    for p in payments:
        if (p.get('status') == 'approved' and str(p.get('external_reference')) == str(order.id)
            and p.get('currency_id') == 'MXN' and Decimal(str(p.get('transaction_amount', 0))) == order.total):
            order.status = 'paid'
            db.commit()
            break
    return order_json(order)
