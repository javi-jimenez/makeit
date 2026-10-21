# Changelog

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
