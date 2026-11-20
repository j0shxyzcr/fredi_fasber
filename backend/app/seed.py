from decimal import Decimal
from sqlalchemy import select
from sqlalchemy.orm import Session
from .models import Lore, Game, Product

LORE = [
 ('El origen de Fazbear Entertainment', 'Una introducción al universo de restaurantes y animatrónicos.',
  'Five Nights at Freddy’s presenta una franquicia ficticia de pizzerías y animatrónicos. La historia se descubre mediante minijuegos, diálogos, secretos y pistas repartidas entre varias entregas. No todo el orden de los acontecimientos está confirmado; muchas cronologías proceden de interpretaciones de la comunidad.'),
 ('Los niños desaparecidos', 'Uno de los misterios centrales que impulsa la historia.',
  'En los juegos se encuentran referencias a desapariciones de niños relacionadas con las pizzerías de Freddy. Los animatrónicos y sus comportamientos extraños forman parte del misterio. Algunas conexiones exactas son tema de debate entre los fans.'),
 ('William Afton y los animatrónicos', 'Personajes, motivaciones y consecuencias en la saga.',
  'William Afton es una figura fundamental en la historia. A lo largo de distintos juegos aparecen pistas sobre sus actos, su familia y las consecuencias que afectan a los animatrónicos. Esta sección resume eventos ampliamente conocidos sin dar una cronología definitiva.'),
 ('La familia Afton', 'Una de las líneas argumentales más analizadas.',
  'Varios juegos aportan elementos relacionados con la familia Afton, como Sister Location y los minijuegos de la serie. Diferencia entre los datos mostrados por los juegos y las teorías publicadas por la comunidad.'),
 ('Pizzaplex y nuevas historias', 'Los eventos más modernos del universo de FNAF.',
  'Security Breach introduce el Mega Pizzaplex y nuevos personajes. Ruin amplía algunos sucesos posteriores. La franquicia continúa agregando material que puede cambiar la interpretación de pistas anteriores.')
]

GAMES = [
 ('Five Nights at Freddy’s', 2014, 'Vigila las cámaras, administra la energía y sobrevive cinco noches en la pizzería.'),
 ('Five Nights at Freddy’s 2', 2014, 'Explora una nueva ubicación, más animatrónicos y una historia narrada con pistas ocultas.'),
 ('Five Nights at Freddy’s 3', 2015, 'Una atracción de terror recupera piezas de la leyenda y presenta a Springtrap.'),
 ('Five Nights at Freddy’s 4', 2015, 'Una experiencia centrada en el miedo, la infancia y las pesadillas.'),
 ('Five Nights at Freddy’s: Sister Location', 2016, 'Una instalación subterránea y nuevos animatrónicos expanden el misterio.'),
 ('Freddy Fazbear’s Pizzeria Simulator', 2017, 'Dirige una pizzería mientras se desarrolla una trama esencial para la saga.'),
 ('Ultimate Custom Night', 2018, 'Supervivencia con una gran selección de animatrónicos y numerosos desafíos.'),
 ('Five Nights at Freddy’s: Help Wanted', 2019, 'Experiencia de realidad virtual que recrea y reinterpreta escenas de la saga.'),
 ('Five Nights at Freddy’s: Security Breach', 2021, 'Explora el Mega Pizzaplex y escapa de los peligros durante la noche.'),
 ('Five Nights at Freddy’s: Help Wanted 2', 2023, 'Nueva colección de experiencias y retos con conexiones al universo moderno.')
]

# Inventario DEMO: precios no oficiales, licencia NO verificada.
PRODUCTS = [
 ('Peluche Freddy — DEMO', 'Freddy', 'Producto de ejemplo. Sustituir por ficha y proveedor autorizado antes de vender.', Decimal('399.00'), 8),
 ('Peluche Bonnie — DEMO', 'Bonnie', 'Producto de ejemplo. Precio e inventario ficticios.', Decimal('389.00'), 6),
 ('Peluche Chica — DEMO', 'Chica', 'Producto de ejemplo. Precio e inventario ficticios.', Decimal('379.00'), 5),
 ('Peluche Foxy — DEMO', 'Foxy', 'Producto de ejemplo. Precio e inventario ficticios.', Decimal('419.00'), 7),
]

def seed_if_empty(db: Session) -> None:
    if db.scalar(select(Lore.id).limit(1)) is None:
        for i, (title, summary, body) in enumerate(LORE):
            db.add(Lore(title=title, summary=summary, body=body, position=i + 1))
    if db.scalar(select(Game.id).limit(1)) is None:
        for name, year, desc in GAMES:
            db.add(Game(name=name, year=year, description=desc))
    if db.scalar(select(Product.id).limit(1)) is None:
        for name, character, desc, price, stock in PRODUCTS:
            db.add(Product(name=name, character=character, description=desc, price=price, stock=stock, official_verified=False))
    db.commit()
