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
    vehicles/    el catalogo precargado de marcas y modelos (solo lectura)
    profiles/    perfil publico: historial de ventas y compras, y ratings
    qa/          preguntas y respuestas publicas
    chat/        chats privados
    notifications/ bandeja de avisos
    home/        carcasa con la barra inferior
```

Cada feature repite las mismas tres capas:

```
features/<nombre>/
  domain/        models, repositories (interfaces con prefijo `I`) y su Failure
  data/
    datasources/   solo hablan con Roble. No deciden nada
    repositories/  deciden, convierten filas en entidades y traducen errores
  ui/            pages, widgets, viewmodels
```

**Un solo repositorio por feature.** No uno por datasource: si hubiera un
`RobleListingRepository` y un `LocalListingRepository`, la decision de cual usar
acabaria en quien llama. Los que son dos son los datasources; el repositorio es
uno y es el mismo en las dos configuraciones.

Los datasources hablan en **filas** —lo que viaja por la API—, no en entidades.
Eso es lo que deja que un repositorio sirva para los dos, y lo que hace que las
pruebas ejerciten el codigo que corre de verdad en vez de una copia:

```dart
AuthRepository(RobleAuthDataSource(cliente))      // app_bindings
AuthRepository(InMemoryAuthDataSource(data))      // local_bindings y pruebas
```

**Las llamadas a Roble viven solo dentro de `data/datasources/`.** Lo unico del
paquete que se nombra fuera son sus **excepciones**, que el repositorio atrapa
para traducirlas al `Failure` de la feature (`ListingFailure`, `QaFailure`,
`ChatFailure`, `AuthFailure`): el `domain/` no sabe que existe HTTP. Se
comprueba de un vistazo:

```bash
grep -rn "\bdb\.\|_client" lib/features/*/data/repositories/*.dart   # vacio
```

| Lo que llega al datasource | Lo que decide el repositorio |
|---|---|
| 403 | «tu cuenta no puede hacer esto»: es de permisos, no se reintenta |
| 404 en update o delete | no existe **o** no es tuyo: el servidor responde igual a proposito |
| lo demas | el mensaje del servidor, envuelto en el `Failure` de la feature |

Los `InMemory...DataSource` son un **backend falso**, no una cache: sirven las
mismas filas que devolveria Roble desde `core/data/dummy_data.dart`. Un
datasource local de cache —el que el skill describe, con el repositorio
eligiendo entre remoto y local— se anadiria el dia que haya requisito de
offline; hoy el repositorio tiene un solo datasource y no hay nada que decidir.

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
| Quien puede calificar a quien, y una sola vez por venta | `RatingRepository` y `UserProfileViewModel` |
| Cambiar de marca vacia el modelo elegido | `CreateListingViewModel` |
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
4. Publicar con caracteristicas — `CreateListingPage`. **Las fotos no estan en
   esta version**: sin almacenamiento no hay donde subirlas, asi que el
   formulario no las pide ni las exige, y la tarjeta se pinta con su color. El
   modelo, las columnas `image_1..3` y `CarPhoto` ya las esperan
5. Preguntas publicas, respuesta publica o chat privado — `features/qa` y
   `features/chat`
6. Seguir una publicacion y recibir avisos de preguntas, respuestas y cambios
   de estado — la estrella del catalogo y del detalle, pestana «Siguiendo»
7. El vendedor recibe aviso de cada pregunta — `QaUseCase.ask`
8. Aviso de mensajes privados salvo chat silenciado — el interruptor de la
   barra del chat

## El esquema en Roble

`roble.schema.desired.json` es el esquema que la app necesita, en el formato
que consume el MCP de Roble. Se aplica asi, desde la raiz del proyecto:

```
roble_schema_plan   (lee el proyecto y dice que falta; no toca nada)
roble_schema_apply  (crea las tablas que faltan; requiere token de escritura)
```

Siete tablas SQL, y **los mensajes de chat no estan entre ellas**:

| Tabla | Para que |
|---|---|
| `listing` | las publicaciones. `buyer_id` / `buyer_name` / `sold_at` se llenan al cerrar la venta |
| `listing_question` | las preguntas publicas, con la respuesta del dueno dentro |
| `listing_follow` | quien sigue que publicacion (a quien hay que avisarle) |
| `chat_thread` | la cabecera de cada chat privado, con `buyer_muted` / `seller_muted` |
| `car_brand` | las marcas precargadas: la tira horizontal del catalogo y el formulario |
| `car_model` | los modelos de cada marca (`brand_id`) |
| `user_rating` | una calificacion por venta y por parte. **Inmutable**: solo se inserta |

Las tres nuevas son **de solo lectura para la app** salvo `user_rating`, que
solo inserta: por eso les basta con lo que Roble le da a una tabla recien
creada (INSERT y SELECT) y no hizo falta tocar roles. `car_brand`, `car_model`
y `user_rating` estan marcadas como **publicas**: la tira de marcas y la
reputacion de un vendedor se tienen que ver antes de crear cuenta, igual que el
catalogo.

El catalogo de vehiculos **lo siembra el proyecto, no la app**: 15 marcas y 89
modelos cargados con `adm-insert` y el token de proyecto. Que sea cerrado es lo
que mantiene util el filtro — escribiendo la marca a mano, «Chevrolet»,
«chevrolet» y «Chevrolett» son tres marcas distintas.

### Entrar sin cuenta: seguir carros como invitado

Marcar la estrella y **preguntar** no exigen cuenta. Si no hay sesion, la app abre una de
invitado (`signInAnonymously`): un usuario de verdad, con `userId`, sin correo
ni clave. Lo que sigue queda a su nombre, y al registrarse lo conserva porque
`upgradeAccount` **muta el usuario que ya existe** en vez de crear otro.

Publicar, chatear y calificar siguen exigiendo cuenta. Por eso la sesion tiene
dos puertas, y confundirlas es el error facil:

| | Que exige | Quien la usa |
|---|---|---|
| `ensureWritableSession()` | sesion, aunque sea de invitado | seguir una publicacion, preguntar |
| `ensureLoggedIn()` | una **cuenta** (`hasAccount`) | publicar, chatear, calificar |

Lo que hubo que tocar en el proyecto de Roble, y no es opcional:

- **Encender el acceso anonimo** (`anonymousAuthEnabled`). El servidor lo niega
  si ninguna tabla acota por dueno: un invitado sin eso escribe filas que
  cualquier otro invitado puede borrar. `listing` y `listing_follow` ya la
  acotan, asi que la condicion se cumplia.
- **Conceder `listing_follow:delete` con alcance `own` al rol `anonymous`.** De
  fabrica ese rol trae solo `create` y `read` sobre lo suyo, asi que un
  invitado podria seguir pero **no dejar de seguir**, y el fallo aparece en el
  segundo toque de la estrella.

### El nombre con el que firma un invitado

Una pregunta **copia el nombre de quien la escribe dentro de la fila**, al
escribirla. Un invitado se llama «Invitado» en el servidor, y registrarse
despues no reescribe lo que ya publico: el vendedor se quedaria sin saber a
quien contesta, para siempre.

Por eso, antes de su **primera** pregunta —no al entrar, que es cuando la gente
se va— se le pide un nombre para mostrar. Vive en `SessionViewModel.guestName`,
firma todo lo que escriba (`session.displayName`) y precarga el formulario de
«guarda tu cuenta», para que la cuenta no nazca con un nombre distinto al de
sus preguntas.

Vive **solo en la sesion**, a proposito: `auth` no deja renombrarse —solo
expone `me/extra`, que el paquete todavia no publica— y la app no guarda nada
en el dispositivo. Al reabrir la app se vuelve a pedir, que es barato: lo ya
publicado quedo firmado.

El chat privado sigue exigiendo cuenta, y no por capricho: mandar un mensaje
actualiza la cabecera del hilo, y `chat_thread` no esta acotada por dueno, asi
que ese permiso dejaria a un invitado tocar cualquier chat.

Y una trampa que costaria cara: **un invitado tiene `isLoggedIn == true` pero
solo lee lo suyo**. `RobleClient.readsPublicly` es lo que evita que el catalogo
salga vacio sin ningun error — con el rol `anonymous`, la lectura normal
devuelve las filas del invitado, que son ninguna.

Al invitado no se le ofrece cerrar sesion: no tiene con que volver a entrar, y
seria borrarle la cuenta sin decirlo. Tampoco se muestra su correo, que es una
direccion inventada `anon_…@anonymous.invalid`.

### Quien puede calificar a quien

Solo las dos partes de una **venta registrada**, y una vez cada una. Por eso la
venta pide comprador: al marcar «Vendido», el vendedor lo elige entre quienes
le abrieron chat por esa publicacion (`BuyerPickerSheet`). Tambien puede cerrar
sin registrar —un carro tambien se vende por fuera—, pero entonces no hay
historial de compra ni calificacion posible.

Sacar una publicacion de «vendido» **borra al comprador**: si no, volveria al
catalogo y seguiria contando como compra de alguien.

Los **mensajes viven en el arbol JSON** (`db.json`), no en SQL: el tiempo real
de Roble emite eventos de las colecciones del arbol, no de las tablas
(`watchTable` esta muerto, el servidor rechaza esas suscripciones). El arbol no
tiene esquema, asi que no hay nada que crear: la coleccion nace con el primer
`push`. La convencion es `chat_message/<thread_id>/<mensaje>`.

> **Suscribirse a una coleccion que no existe se rechaza** con
> `REALTIME_UNKNOWN_COLLECTION`. Un chat recien creado tiene que escribir su
> primer mensaje antes de que alguien pueda escucharlo. Verificado el
> 2026-09-07 contra el servidor de test: escuchar primero falla, y escribir
> antes de escuchar entrega el evento.

### Filas propias: quien puede tocar que

Desde el **2026-09-10** dos tablas estan acotadas por dueno en el servidor
—`listing` y `listing_follow`, en actualizar y borrar—, aplicado con
`roble_schema_apply` desde el `"owns": true` del esquema deseado.

| Tabla | Acotada | Por que |
|---|---|---|
| `listing` | update, delete | el catalogo lo ve cualquiera, pero la publicacion la cambia solo su vendedor |
| `listing_follow` | update, delete | cada quien crea y borra su propio seguimiento |
| `listing_question` | no | la respuesta la escribe el **vendedor** sobre la fila que creo el comprador: acotarla romperia responder |
| `chat_thread` | no | los **dos** participantes la actualizan al mandar un mensaje |

La lectura no se acota en ninguna: `listing` y `listing_question` se leen sin
sesion a proposito, y `followerIdsOf` necesita ver de quien es cada seguimiento
para saber a quien avisar.

Si algun dia quieres acotar tambien `listing_question`, la forma es sacar la
respuesta a su propia tabla, con el vendedor de dueno.

**Esto no acota nada por si solo.** Son dos interruptores: la propiedad por fila
de la tabla (esto, ya hecho) y los permisos con alcance `own` del rol de los
usuarios (abajo, en la consola).

Y cambia un error: tocar una fila que no es tuya responde **404**, el mismo que
si no existiera. `RobleClient.guardOwnership` lo traduce para que la pantalla no
diga «no existe» cuando lo que pasa es que no es tuyo.

### La sesion que se cae sola

`IAuthRepository.sessionExpired` lleva `db.onSessionExpired` hasta
`SessionViewModel`, que borra al usuario y manda al login diciendo que caduco.
Sin eso, una sesion caducada se descubre por el 401 de la siguiente pantalla que
pida datos: tarde, y una pantalla cada vez. Cerrar sesion a proposito **no**
emite ahi, asi que solo se explica lo que merece explicacion.

### Los mensajes del chat no tienen dueno

El arbol JSON puede exigir que la ruta sea tuya, pero eso marca **un segmento**
como el del dueno, y en `chat_message/<threadId>/...` el segundo segmento es el
hilo, no la persona: los dos participantes escriben ahi. Consecuencia, y conviene
saberla: **cualquier usuario con sesion puede escribir en cualquier chat** si
llama a la API directamente. La app no lo ofrece; el servidor no lo impide.

Acotarlo pediria cambiar la ruta a `chat_message/<userId>/...`, que rompe leer un
hilo de un viaje. No se hizo.

### Permisos: los aplica el MCP

El rol `user` de un proyecto nuevo trae `all:create`, `all:read` y `all:execute`
y nada mas, asi que el primer `update` de la app responderia 403. Lo que la app
necesita se declara en `roble.schema.desired.json` (`uses` y `owns`) y
`roble_schema_apply` lo concede:

| Permiso | Alcance | Quien lo ejecuta |
|---|---|---|
| `listing:update` | `own` | el vendedor, sobre su publicacion |
| `listing_follow:delete` | `own` | cada quien, sobre su seguimiento |
| `listing_question:update` | `all` | el **vendedor**, sobre la fila del comprador |
| `chat_thread:update` | `all` | **los dos** participantes |

Los dos ultimos van con alcance `all` porque ahi escribe alguien que no es el
dueno de la fila; con `own` recibirian 404 sobre algo que si existe. Por eso
tampoco se acota por dueno esas dos tablas.

La app **no borra publicaciones** —las retira con el estado `withdrawn`—, asi
que no pide `listing:delete`.

`listing` y `listing_question` estan marcadas como **publicas**, que es lo que
hace visible el catalogo sin sesion (requisito 3). Eso tambien lo aplica el
apply, desde el `"public": true` del esquema.

Comprobado el 2026-09-10 con dos cuentas: cambiar el estado de lo propio pasa,
tocar lo ajeno responde 404, y el catalogo se lee sin sesion.

### Las fotos, cuando lleguen

`listing` las guarda en `image_1`, `image_2` e `image_3`, y **solo viajan
URLs**: una ruta del telefono no le sirve a ningun otro dispositivo, asi que el
repositorio la descarta en vez de ensuciar la tabla con algo que nadie puede
abrir. Mientras no haya almacenamiento las tres van vacias.

### Por que no un jsonb

`listing` guarda las fotos en `image_1`, `image_2` e `image_3`, no en una
lista. **La API rechaza los arrays JSON** en una columna `jsonb` (400
«Conversión inválida») y convierte `[]` en `{}`; solo acepta objetos. Como el
requisito ya limita a tres fotos, tres columnas dejan el tope estructural y se
leen de un viaje.

### El smoke

`test/smoke_test.dart` comprueba la conexion real: registra una cuenta
desechable, entra, escribe en el arbol JSON, escucha el cambio y borra lo que
creo. Se corre a mano, no en CI:

```bash
set -a && . ./.roble.mcp.env && set +a
flutter test test/smoke_test.dart --reporter expanded
```

Es el que trae la skill `use-roble` con **una correccion**: el original escucha
la coleccion antes de crearla, y por eso su paso de tiempo real no puede pasar.

### La prueba de integracion

`test/roble_integration_test.dart` recorre el flujo entero contra el servidor
—publicar, seguir, preguntar, responder, cambiar de estado, chatear con tiempo
real— con dos cuentas desechables que se borran al terminar. Se corre igual que
el smoke, y **necesita los permisos de arriba**: sin ellos falla en la primera
operacion que no sea INSERT o SELECT.

Roble no tiene claves foraneas: `listing_id` apuntando a `listing._id` es
convencion de nombres. Por eso los nombres van denormalizados en las filas
(`seller_name`, `asker_name`): la API de lectura tampoco hace joins, y una
consulta guardada para cada nombre seria peor.

## Fase 2: conectar Roble

Se resuelve escribiendo cinco repositorios contra el paquete `roble` —los
mismos `I...Repository`— y cambiando las lineas correspondientes de
`lib/di/app_bindings.dart`. Nada mas de la app deberia moverse.

Las fotos de prueba son ilustraciones en `assets/cars/`. Con Roble pasaran a
ser URLs: `CarPhoto` ya distingue asset, URL y fichero local, y pinta un
relleno de color cuando la publicacion no tiene fotos.
