# f_roble_market

Mercado de carros usados: catalogo publico, publicaciones con fotos, preguntas
publicas y chat privado, con avisos para el vendedor y para quien sigue una
publicacion.

**Estado: fase 1.** Toda la UI esta construida y funciona contra una fuente de
datos local en memoria (`lib/core/data/dummy_data.dart`). Todavia no habla con
Roble; la fase 2 sustituye los repositorios locales por los de Roble sin tocar
la UI ni los view models.

## Como correrlo

```bash
flutter pub get
flutter run
```

Cuenta de prueba: `ana@demo.com` / `123456`. El boton de Google entra con esa
misma cuenta mientras no haya proveedor real.

## Arquitectura

Clean architecture **por feature**, con MVVM en la capa de presentacion y GetX
para navegacion e inyeccion. **No hay casos de uso**: la logica vive en los
view models, que hablan directamente con las interfaces de los repositorios.

```
lib/
  core/          lo transversal: tema, formatos, widgets compartidos y la
                 fuente de datos de prueba
  di/            AppBindings: el unico sitio que decide que implementacion
                 concreta se usa
  routes/        nombres de ruta y GetPages con sus bindings
  features/
    auth/        sesion, login, registro, perfil
    listings/    catalogo, detalle, publicar, lo mio
    qa/          preguntas y respuestas publicas
    chat/        chats privados
    notifications/ bandeja de avisos
    home/        carcasa con la barra inferior
```

Cada feature repite las mismas tres capas:

```
features/<nombre>/
  domain/        models y repositories (interfaces, con prefijo `I`)
  data/          implementaciones de los repositorios (`Local...`)
  ui/            pages, widgets, viewmodels
```

La regla de dependencia va hacia adentro: `ui` conoce `domain`, `data`
implementa `domain`, y `domain` no conoce a nadie. Las interfaces empiezan por
`I` (`IListingRepository`, `IChatRepository`, `INotificationDispatcher`) para
distinguirlas de un vistazo de sus implementaciones.

Los view models solo escriben texto en `message` y `error`; quien pinta el
snackbar es la vista, con el mixin `MessageListener`. Por eso se pueden probar
sin Flutter.

### Donde estan las reglas de negocio

No en los widgets: los view models son quienes deciden.

| Regla | Donde vive |
|---|---|
| Validar el formulario de publicacion (max. 3 fotos, ano, precio) | `CreateListingViewModel` |
| Solo el dueno responde en publico; nadie pregunta en lo suyo | `ListingDetailViewModel` |
| A quien se le avisa de una pregunta o una respuesta | `ListingDetailViewModel` |
| A quien se le avisa de un cambio de estado | `ListingDetailViewModel` y `MyListingsViewModel` |
| Un chat silenciado no genera avisos | `ChatViewModel` |
| Validar correo y contrasena | `SessionViewModel` |

El cambio de estado se puede hacer desde dos pantallas, asi que su regla esta
escrita en los dos view models: si cambia una, hay que cambiar la otra.

### Las notificaciones

`INotificationDispatcher` esta separado de `INotificationRepository` a proposito.
La bandeja se lee siempre igual, pero **quien produce** los avisos cambia entre
fases: hoy los produce la propia app (`LocalNotificationRepository` implementa
las dos interfaces), y con Roble los producira el servidor, asi que la
implementacion de `dispatch` pasara a no hacer nada.

Seguir una publicacion (la estrella) es lo que suscribe a un comprador a los
avisos de preguntas, respuestas y cambios de estado de esa publicacion.

## Requisitos y donde se ven

1. Mercado de carros — `features/listings`
2. Login por correo y con Google — `features/auth`
3. Catalogo visible sin sesion — `CatalogPage`, sin guardas de ruta
4. Publicar con caracteristicas y hasta 3 fotos — `CreateListingPage`
5. Preguntas publicas, respuesta publica o chat privado — `features/qa` y
   `features/chat`
6. Seguir una publicacion y recibir avisos de preguntas, respuestas y cambios
   de estado — la estrella del catalogo y del detalle, pestana «Siguiendo»
7. El vendedor recibe aviso de cada pregunta — `QaUseCase.ask`
8. Aviso de mensajes privados salvo chat silenciado — el interruptor de la
   barra del chat

## Fase 2: conectar Roble

Se resuelve escribiendo cinco repositorios contra el paquete `roble` —los
mismos `I...Repository`— y cambiando las lineas correspondientes de
`lib/di/app_bindings.dart`. Nada mas de la app deberia moverse.

Las fotos de prueba son ilustraciones en `assets/cars/`. Con Roble pasaran a
ser URLs: `CarPhoto` ya distingue asset, URL y fichero local, y pinta un
relleno de color cuando la publicacion no tiene fotos.
