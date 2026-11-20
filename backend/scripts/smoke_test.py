"""Prueba manual local: con FastAPI/MySQL iniciados, ejecuta python -m scripts.smoke_test.
Crea una cuenta y registros de prueba. No realiza pagos.
"""
import json
import os
import secrets
import urllib.error
import urllib.request

base = os.getenv('API_BASE_URL', 'http://127.0.0.1:8000')
token = None


def call(path, method='GET', data=None):
    payload = None if data is None else json.dumps(data).encode('utf-8')
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    request = urllib.request.Request(base + path, method=method, data=payload, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return json.loads(response.read())
    except urllib.error.HTTPError as error:
        print('ERROR', path, error.code, error.read().decode('utf-8'))
        raise


def main():
    global token
    suffix = secrets.token_hex(4)
    assert call('/health')['status'] == 'ok'
    data = call('/auth/register', 'POST', {
        'username': 'prueba_' + suffix,
        'email': f'prueba_{suffix}@example.com',
        'password': secrets.token_urlsafe(16)
    })
    token = data['access_token']
    assert call('/auth/me')['id'] == data['user']['id']
    post = call('/posts', 'POST', {'content': 'Prueba automática del lore de FNAF'})
    reaction = call(f"/posts/{post['id']}/reactions", 'POST', {'kind': 'love'})
    assert reaction['my_reaction'] == 'love'
    comment = call(f"/posts/{post['id']}/comments", 'POST', {'content': 'Este misterio está interesante'})
    assert comment['author'] == data['user']['username']
    assert any(x['id'] == post['id'] for x in call('/posts'))
    assert call('/lore') and call('/games') and call('/products')
    products = call('/products')
    order = call('/orders', 'POST', {'items': [{'product_id': products[0]['id'], 'quantity': 1}]})
    assert order['status'] == 'pending_payment'
    assert any(x['id'] == order['id'] for x in call('/orders'))
    print('OK: salud, JWT, usuarios, publicaciones, reacciones, comentarios, lore, juegos, tienda y pedidos DEMO.')
    print('Cuenta y pedido de prueba:', data['user']['username'], '#'+str(order['id']))


if __name__ == '__main__':
    main()
