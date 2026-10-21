# Changelog

## [0.3.2] — 2026-10-21

### Añadido

- **Publicación del repositorio**: GitHub (`javi-jimenez/makeit`) y Gitea
  (`gitea/makeit`), ambos públicos, con los tags `0.2.1`, `0.3.0` y `0.3.1`.
- **El Makefile de makeit configura su propia réplica** — `GIT_REMOTES="origin
  gitea"` y `GIT_SLOW_REMOTES=gitea` — para que sirva de ejemplo real de la
  configuración que el README describe.

### Decidido

- **El transporte a Gitea es SSH, no HTTPS.** El almacén de credenciales HTTP de
  esta máquina se quedó sin la contraseña (GCM no puede escribir en el llavero:
  `Failed to open secret service session`) y depender de un token guardado a mano
  era frágil. La clave `hek-push` ya está registrada en Gitea y el agente la
  tiene cargada: cero prompts, cero secretos en disco.
- **Los repos nuevos se crean por API, no por push.** Gitea tiene
  `ENABLE_PUSH_CREATE_USER=false`, así que un `push` a un repo inexistente falla
  con "Push to create is not enabled". Crear el repo requiere `write:user`.

## [0.3.1] — 2026-10-21

### Añadido

- **`GIT_SLOW_REMOTES`, `GIT_SLOW_GIT_OPTS`, `GIT_SLOW_PUSH_OPTS`** — remotos
  cuyo almacén no soporta packs grandes empujan con `-c pack.threads=1
  --no-thin` sólo ellos. El matcher compara **nombre y URL**, así que
  `GIT_SLOW_REMOTES=gitea` vale igual si el remoto se llama `gitea` o si apunta
  a `gitea.dominio.tld`.

### Corregido

- **Los flags de push no pueden ir en una sola variable.** `-c` es una opción
  global de git y `--no-thin` es una opción del subcomando: juntas producen
  `git push -c ...` y git imprime la ayuda. Se devuelven como dos grupos
  separados por `|` y se expanden **sin comillas** para que se dividan en
  palabras.

### Decidido

- **El workaround vive en el framework, no en cada proyecto.** El fallo es del
  servidor (fs sin locking), no del repo, así que el conocimiento pertenece
  donde se comparte: declarar `GIT_SLOW_REMOTES` y olvidarse.
- **La detección es declarativa, no por sondeo.** No se comprueba si el servidor
  es rápido: se marca. Un test de velocidad en cada push costaría más que el
  propio push y sería frágil.

## [0.3.0] — 2026-10-21

### Añadido

- **`push-all` y `GIT_REMOTES`** — empuje a varios remotos en un solo comando
  (réplica GitHub + Gitea). Un commit, un push por remoto, y **el fallo de uno no
  impide los demás ni oculta la salida del que falló**.
- **`push-tags` acepta varios remotos** (antes sólo `GIT_REMOTE`).
- **`release`** — existía en la tabla del README pero **no estaba implementado**.
  Ahora hace `tag` + `push-tags`, que es lo que prometía la documentación.
- **`install-hooks`** — instala los hooks del proyecto: ejecuta
  `tools/install-git-hooks.sh` si existe y, si no, apunta `core.hooksPath` a `.githooks/`.
- **Fallback a Docker en `modules/hugo.mk`** (`HUGO_DOCKER_IMAGE`, patrón D2) para
  `build`, `serve` y `hugo-check`: si no hay binario de Hugo ni en `./.bin` ni en el
  PATH, se usa la imagen oficial. Antes el módulo exigía Hugo instalado en el host.

### Corregido

- **`tag` dejaba la entrada del CHANGELOG fuera del tag.** Se creaba el fichero,
  pero el tag se hacía sobre el commit anterior, así que el árbol etiquetado no
  contenía la entrada que el propio `tag` acababa de generar. Ahora la commitea
  antes de etiquetar.
- **`tag` no creaba `CHANGELOG.md` si el fichero no existía** (el `-f` de la guarda
  lo impedía), justo el caso de un proyecto nuevo.

### Decidido

- **El fallo de un remoto no aborta la réplica, pero sí el código de salida.** En
  una réplica interesa intentar todos los destinos (uno puede estar caído) y aun
  así fallar visiblemente, para no dar por buena una subida a medias.
- **El patrón D2 (usar la herramienta del entorno; si falta, contenedor oficial)
  sube del proyecto al framework.** Venía probado en `jimenezgomez.org`, donde el
  mismo Makefile corre en local, Drone y GitHub Actions; es genérico y evita la
  instalación de Hugo en el host, que es justo lo que makeit promete no necesitar.

## [0.2.1] — 2026-10-21

### Añadido

- **`make tag` crea la entrada del CHANGELOG automáticamente.** Si existe `CHANGELOG.md`
  y no tiene sección para la versión que se está etiquetando, inserta una vacía con los
  cuatro apartados. Desactivable con `CHANGELOG_AUTO=0`.

### Corregido

- **`$(C_YELLOW)` no existe** — la variable es `$(C_YELL)`. El mensaje del tag salía vacío.
- Se declara `CHANGELOG_AUTO` como variable documentada, no implícita.

### Decidido

- **La entrada se crea vacía, no se rellena sola.** El mensaje del commit no es un
  changelog: dice qué se tocó, no por qué. Generar el «porqué» automáticamente sería
  inventarlo.

## [0.2.0] — 2026-10-21

### Añadido

- **`make readme-check`** — falla si falta `README.md` o `CHANGELOG.md`, o si no
  mencionan la versión de `VERSION`. Es la política convertida en target, para que se
  pueda comprobar en lugar de recordar.
- **`make changelog-new`** — inserta la entrada de la versión actual al principio del
  CHANGELOG con los cuatro apartados (`Añadido`, `Cambiado`, `Corregido`, `Decidido`).
- **Sección «Política de versión visible»** en el README: un tag es invisible desde
  dentro del proyecto, así que la versión debe estar en el README y cada cambio en el
  CHANGELOG, cada entrada diciendo el **porqué** y no solo el qué.

### Cambiado

- La tabla de módulos del README incluye los dos targets nuevos.

### Decidido

- **El razonamiento se documenta, no solo el cambio.** «Se renombró WP7» no sirve; «se
  renombró porque una afirmación jurídica se puede comprobar y una ética no» sí. El
  razonamiento es lo primero que se pierde y lo más caro de reconstruir.
- **Las decisiones negativas también se registran.** Son las que se deshacen por
  accidente.
- **Un CHANGELOG refleja lo que hay en el tag, no lo que hay en el árbol.** Lo que está a
  medias va en una sección *Open* al final, no como si estuviera hecho.
- **Si `VERSION` está excluido por `.gitignore`** (habitual en repos que solo versionan
  markdown), la versión vive en el tag y en el README. Es correcto: el tag es inmutable y
  el fichero no.
