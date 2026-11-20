# FAZBEAR ARCHIVES | Evaluación Unidad 3

**Proyecto escolar NO OFICIAL**, creado por fans de Five Nights at Freddy's. Se compone de una app móvil en Flutter, una API en FastAPI y una base de datos MySQL.

## Funciones incluidas

- Registro, inicio de sesión, contraseña con hash Argon2 y sesión JWT guardada con `flutter_secure_storage`.
- Inicio con secciones de **Lore**, **Juegos**, **Episodios del vlog**, **Comunidad** y **Tienda**.
- Lore por capítulos, con introducciones y aclaraciones sobre teorías.
- Catálogo de juegos en orden de publicación.
- Episodios de vlog: el administrador enlaza videos de YouTube y los usuarios pueden abrirlos en su reproductor.
- Publicaciones de texto de los usuarios, comentarios y reacciones tipo Facebook (👍 ❤️ 😆 😮 😢 😡).
- Catálogo de peluches, cantidades, carrito, creación de pedidos y consulta de pedidos.
- Integración preparada para obtener un enlace de Mercado Pago Checkout Pro **solo cuando hay credenciales reales y productos verificados**.
- Endpoints de administración para agregar lore, episodios de video y productos.

### Advertencia sobre la tienda

Los cuatro peluches que se crean inicialmente son **datos de demostración**, con precios e inventario ficticios y `official_verified=false`. No son inventario real ni se afirma que estén licenciados. **La API rechaza el cobro de cualquier pedido que contenga productos no verificados.** Para operar una tienda real, consigue proveedor autorizado, fichas y comprobantes de producto oficial, inventario válido, cuentas de pago y condiciones de envío. El cobro de prueba no sustituye una implementación de comercio electrónico lista para producción.

## Estructura

```text
Fazbear_Archives_U3/
├── flutter_app/
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── api.dart
│       ├── theme.dart
│       └── screens/
│           ├── auth_screen.dart
│           ├── main_shell.dart
│           ├── lore_games.dart
│           ├── episodes_screen.dart
│           ├── feed_screen.dart
│           └── store_screen.dart
├── backend/
│   ├── app/              # Modelos, JWT, API, datos de demostración
│   ├── scripts/          # Administrar roles
│   ├── requirements.txt
│   └── .env.example
├── database/schema.sql
└── docs/REPORTE_TECNICO_BASE.md
```

> **Nota:** Se entrega el código fuente de Flutter, sin el código generado automáticamente de Android/iOS/web. El primer `flutter create` de las instrucciones crea esos archivos de plataforma. No requiere reescribir `lib/`.

## 1. Preparar MySQL (XAMPP en Windows)

1. Abre **XAMPP Control Panel** e inicia **MySQL**.
2. Abre `http://localhost/phpmyadmin`.
3. En la pestaña **SQL**, pega y ejecuta `database/schema.sql`. Esto crea `fnaf_archives` y las tablas.
4. En MySQL, crea un usuario dedicado (mejor práctica); por ejemplo, ejecuta cambiando la clave:

```sql
CREATE USER 'fnaf_user'@'localhost' IDENTIFIED BY 'UNA_CONTRASENA_FUERTE';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX ON fnaf_archives.* TO 'fnaf_user'@'localhost';
FLUSH PRIVILEGES;
```

5. Si no creas el usuario, para desarrollo puedes utilizar las credenciales locales de XAMPP, pero **no uses `root` con contraseña vacía en un servidor público**.

## 2. Levantar FastAPI

En **Terminal de VS Code** o PowerShell:

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

Edita `backend/.env`:

```ini
DATABASE_URL=mysql+pymysql://fnaf_user:UNA_CONTRASENA_FUERTE@127.0.0.1:3306/fnaf_archives?charset=utf8mb4
JWT_SECRET=PEGA_AQUI_UN_SECRETO_ALEATORIO
ACCESS_TOKEN_MINUTES=120
MP_ACCESS_TOKEN=
MP_RETURN_URL=
```

Genera un secreto seguro así:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Pega su resultado en `JWT_SECRET`. **No subas `.env` a GitHub.** Si tu contraseña MySQL lleva caracteres como `@` o `#`, codifícalos en la URL (`%40`, `%23`).

Inicia la API:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Prueba en tu navegador:

- `http://localhost:8000/health` → `{"status":"ok"}`
- `http://localhost:8000/docs` → documentación interactiva de todos los endpoints.

En el primer arranque, la API crea los capítulos, lista de juegos y productos **de ejemplo** si las tablas están vacías. **No** crea usuarios ni contraseñas predeterminadas.

## 3. Preparar Flutter

Abre **otra terminal** (deja FastAPI corriendo):

```powershell
cd flutter_app
flutter create --platforms=android,web .
flutter pub get
```

Si Flutter te pide confirmar reemplazar archivos, **conserva `pubspec.yaml` y `lib/` que vienen en esta entrega**. El comando genera los directorios de plataforma que faltan.

### Probar en Chrome

```powershell
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:8000
```

### Probar en el emulador de Android

En `flutter_app/android/app/src/main/AndroidManifest.xml`, **fuera** de `<application>`, dentro de `<manifest>`, agrega:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Para pruebas locales HTTP, dentro de la etiqueta `<application ...>` agrega temporalmente:

```xml
android:usesCleartextTraffic="true"
```

Después, con el emulador abierto:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`emulator-5554` es solo un ejemplo; consulta los dispositivos conectados con `flutter devices`.

### Probar en tu celular Android

- Tu laptop y teléfono deben estar en la misma red.
- Revisa la **IP local de tu laptop** con `ipconfig` (por ejemplo `192.168.1.20`).
- En Firewall de Windows, permite Python/puerto 8000 en redes privadas.
- Activa depuración USB, comprueba con `flutter devices` y ejecuta:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Cambia `192.168.1.20` por **tu IP real**. Para despliegue real debes usar HTTPS y quitar el permiso de tráfico HTTP sin cifrar.

## 4. Primer uso

1. En la app elige **Regístrate**; crea un nombre, correo y contraseña (mínimo 8 caracteres).
2. Abre **Lore** y **Juegos**; los contenidos se leen desde MySQL a través de FastAPI.
3. Abre **Comunidad**, publica una teoría, reacciona a la publicación y agrega comentarios.
4. Abre **Tienda**, añade productos al carrito y crea un pedido de demostración. Debe quedar como `pending_payment`. No se cobran los productos de ejemplo.
5. En el botón circular de la esquina superior derecha consulta **Mi perfil → Mis pedidos**.

## 5. Subir episodios al vlog (YouTube)

Primero crea una cuenta desde Flutter. En la terminal de `backend/` ejecuta:

```powershell
python -m scripts.promote_admin TU_USUARIO
```

En `http://localhost:8000/docs`:

1. Abre `POST /auth/login` y envía tu correo y contraseña. Copia el `access_token`.
2. Presiona **Authorize** e introduce el token para `HTTPBearer` (si Swagger solicita el valor, pega el token sin el prefijo `Bearer`).
3. Abre `POST /admin/episodes` y envía un título, descripción y URL pública HTTPS de YouTube:

```json
{
  "title": "Episodio 1: el origen de Freddy",
  "description": "Explicamos el comienzo y las pistas más importantes de los primeros juegos.",
  "video_url": "https://www.youtube.com/watch?v=ID_REAL_DEL_VIDEO"
}
```

Reemplaza `ID_REAL_DEL_VIDEO` por la URL del video que el equipo haya publicado. Si todavía no tienen videos, la app muestra “Próximamente”. También existen `POST /admin/lore` y `POST /admin/products`. No existe una contraseña de administrador predeterminada.

## 6. Cobros en línea (módulo condicionado)

La API incluye `POST /orders/{id}/checkout` para obtener un enlace de Mercado Pago y `POST /orders/{id}/verify-payment` para consultar un pago aprobado desde Mercado Pago. Sin credenciales, el primer endpoint responde 503. Si un pedido tiene productos no verificados, se rechaza el cobro. Para habilitar compras reales:

1. Consigue un proveedor de artículos FNAF **oficiales y verificables** y prepara fichas, existencias, precios reales, impuestos y condiciones de envío.
2. Crea productos con `official_verified=true` **solo** si realmente has verificado su origen.
3. Configura un vendedor en Mercado Pago e introduce `MP_ACCESS_TOKEN` en `.env` del backend, nunca en Flutter.
4. Prueba el flujo con cuentas/credenciales de prueba del proveedor; la API utiliza Preferences API (Checkout Pro).
5. Agrega **antes de lanzar** una solución fiable de envíos, actualización transaccional de existencias, control de pedidos pendientes, webhooks con firma, cancelaciones/reembolsos, impuestos, protección de datos y pruebas de pago en producción. El endpoint de verificación es manual y **no sustituye** la conciliación automática.

La documentación de Mercado Pago puede cambiar: https://www.mercadopago.com.mx/developers/es/docs/checkout-pro-preferences/overview

## 7. Prueba de integración desde la terminal

Con MySQL y FastAPI corriendo, puedes probar la API de extremo a extremo con este script. **Crea datos de prueba** (cuenta, publicación, comentario, reacción y pedido no pagado):

```powershell
cd backend
python -m scripts.smoke_test
```

Si imprime `OK`, las rutas centrales de lectura y escritura funcionan en tu equipo. Revisa también las pantallas de Flutter manualmente.

## 8. Subir a GitHub

El repositorio público debe contener Flutter, FastAPI, `database/schema.sql`, `README.md`, el reporte digital y capturas obtenidas por ustedes. No incluyas `.env`, bases de datos reales, tokens, contraseñas ni archivos de plataforma con datos privados. El `.gitignore` protege los principales archivos sensibles.

## 9. Checklist de evaluación

- [x] Código Flutter / FastAPI / script SQL
- [x] Registro, login, hash de contraseñas Argon2, JWT
- [x] Publicaciones y comentarios
- [x] Reacciones interactivas
- [x] Catálogo, carrito y registro de pedidos
- [x] Lore, juegos y módulo del vlog
- [x] README con instalación y uso
- [ ] Probarlo en el equipo del estudiante y tomar **capturas reales** de las pantallas y de MySQL
- [ ] Grabar y publicar episodios reales (opcional a la rúbrica)
- [ ] Configurar proveedor y pago real, solo si se decide hacer ventas (alcance extendido)
- [ ] Publicar repositorio público en GitHub (acción manual del equipo)

**Estado de esta entrega:** código fuente preparado; no se ha ejecutado Flutter aquí porque Flutter SDK no está instalado en el entorno donde se construyó la entrega. Es necesario realizar pruebas de compilación y conexión en el equipo del estudiante.
