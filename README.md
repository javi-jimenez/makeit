# makeit

**Versión: 0.3.0** · [CHANGELOG](CHANGELOG.md)

Framework de **Makefiles modulares y reutilizables** para cualquier proyecto.

En lugar de copiar y pegar un Makefile enorme en cada repo, incluyes solo los
módulos que necesitas y todos los proyectos comparten los mismos comandos
estándar: `make push`, `make deploy`, `make test`, `make ftp-upload`, `make help`.

## Filosofía

- **Modular**: cada módulo cubre un tipo de tarea (git, ftp, hugo, docker, test…).
- **Composable**: incluyes los módulos que quieras en el Makefile de tu proyecto.
- **Sobreescribible**: cada módulo define variables con valores por defecto que
  tu proyecto puede cambiar (en el propio Makefile o en `.env`).
- **Auto-documentado**: `make help` lista todos los targets disponibles.
- **Sin dependencias**: solo `make` y `bash` (y las herramientas que use cada
  módulo, como `lftp` o `docker`).

## Instalación

Clona makeit en cualquier ruta y apunta a ella desde tus proyectos:

```bash
git clone <url> ~/data/repo/makeit
```

## Uso

En el `Makefile` de tu proyecto:

```makefile
# 1) Configuración del proyecto ANTES de los include (sobreescribe defaults).
PROJECT    ?= mi-sitio
FTP_SERVER ?= ftp://ftp.example.org
FTP_REMOTE_PATH ?= /public_html/

# 2) Ruta a makeit y núcleo.
MAKEIT ?= $(HOME)/data/repo/makeit
include $(MAKEIT)/makeit.mk

# 3) Módulos que necesites.
include $(MAKEIT)/modules/git.mk
include $(MAKEIT)/modules/ftp.mk
include $(MAKEIT)/modules/hugo.mk
```

> **Orden importa**: define tus variables **antes** de los `include` para que
> sobreescriban los valores por defecto de makeit (comportamiento estándar de
> Make). También puedes ponerlas en `.env`.

Y ya tienes:

```bash
make help          # lista de comandos disponibles
make push          # git add + commit + push
make deploy        # build (Hugo) + subida por FTP
make ftp-upload    # sube el directorio local por FTP
make serve         # servidor de desarrollo de Hugo
```

## Módulos

| Módulo | Comandos principales |
|---|---|
| `makeit.mk` (core) | `help`, `version`, `version-bump`, `readme-check`, `changelog-new` |
| `modules/git.mk` | `push`, `push-all`, `pull`, `git-status`, `git-commit`, `tag`, `push-tags`, `release`, `install-hooks` |
| `modules/ftp.mk` | `ftp-upload`, `ftp-dry-run` |
| `modules/hugo.mk` | `build`, `serve`, `clean`, `deploy`, `hugo-install`, `hugo-check` |
| `modules/test.mk` | `test`, `lint` |
| `modules/docker.mk` | `docker-build`, `docker-push`, `docker-run` |
| `modules/clean.mk` | `clean-all` |

## Configuración

Copia `.env.example` a `.env` y rellena los valores. El `.env` no se versiona.
También puedes sobreescribir variables directamente en el Makefile del proyecto.

### Variables comunes

| Variable | Default | Descripción |
|---|---|---|
| `PROJECT` | nombre del directorio | Nombre del proyecto |
| `GIT_REMOTE` | `origin` | Remoto git |
| `GIT_REMOTES` | _(vacío → `GIT_REMOTE`)_ | Remotos de `push-all` / `push-tags` (ej: `"origin gitea"`) |
| `GIT_BRANCH` | `main` | Rama git |
| `COMMIT_MSG` | `Automated commit by makeit` | Mensaje de commit |
| `FTP_SERVER` | — | Host/URL FTP |
| `FTP_USERNAME` | — | Usuario FTP |
| `FTP_PASSWORD` | — | Contraseña FTP |
| `FTP_REMOTE_PATH` | `/` | Ruta remota destino |
| `FTP_LOCAL_DIR` | `public` | Directorio local a subir |
| `HUGO_VERSION` | `0.152.2` | Versión de Hugo |
| `HUGO_DOCKER_IMAGE` | `ghcr.io/gohugoio/hugo:latest` | Imagen usada si no hay Hugo en el host |

### Réplica en dos forjas (GitHub + Gitea)

Si el repo vive en más de un sitio, no dupliques el empuje en scripts:

```bash
make push-all      # un commit, un push por remoto; el fallo de uno no oculta los demás
make release       # tag + subida de tags a todos los remotos
```
```makefile
GIT_REMOTES ?= origin gitea
```

`push-all` y `push-tags` **siguen con el resto de remotos si uno falla** e imprimen
la salida del que haya fallado: en una réplica, saber *cuál* falló importa más que
saber que algo falló.

## Versionado

La versión del proyecto se guarda en `./VERSION` y se gestiona con `make version`:

```bash
make version            # muestra la versión actual del proyecto
make version VERSION=1.0.1   # establece la versión a 1.0.1
make version-bump BUMP=patch # sube la versión (major|minor|patch)
```

Los tags incluyen **timestamp** `YYYYMMDDHHMM` para que cada etiqueta sea única:

```bash
make tag                # -> 1.0.1-202610082159  (usa la versión de ./VERSION)
make release            # crea el tag y lo sube a GIT_REMOTES (tag + push-tags)
make readme-check       # avisa si falta README o CHANGELOG, o si discrepan
make changelog-new      # inserta la entrada de la versión actual a mano
```

**`make tag` deja la entrada del CHANGELOG dentro del tag.** Si falta la sección de
la versión, la crea vacía, **la commitea** y luego etiqueta. Sin ese commit la
entrada quedaría fuera del tag, y entonces el CHANGELOG describiría un árbol que no
es el etiquetado. Se desactiva con `CHANGELOG_AUTO=0`.

El control de major/minor/patch es tuyo (con `make version` o `make version-bump`);
el timestamp lo añade makeit automáticamente.

### Política de versión visible: `README.md` + `CHANGELOG.md`

Un tag de git es invisible desde dentro del proyecto. Cualquiera que abra la carpeta
—tú dentro de tres meses, o un colaborador— no ve la versión en ningún sitio. Por eso
**todo proyecto versionado con makeit lleva dos ficheros en la raíz**:

| Fichero | Contenido | Cambia |
|---|---|---|
| `README.md` | **La versión actual, arriba del todo.** Qué es el proyecto, cómo se construye, qué está bloqueado, las cifras clave | Cuando cambia la versión |
| `CHANGELOG.md` | Una entrada por versión: qué cambió y **por qué** | Cada versión |

**Reglas:**

1. **La versión aparece en el README en las primeras líneas**, no al final. Es lo primero
   que se busca.
2. **El CHANGELOG va en orden inverso** (lo más nuevo arriba) y **una entrada por tag**.
   `make tag` la crea sola si falta.
3. **Cada entrada dice el porqué, no solo el qué.** «Se renombró WP7» no sirve; «se
   renombró porque una afirmación jurídica se puede comprobar y una ética no» sí. El
   razonamiento es lo primero que se pierde y lo más caro de reconstruir.
4. **Se documenta también lo que se decidió no hacer**, y por qué. Las decisiones negativas
   son las que se deshacen por accidente.
5. **El CHANGELOG refleja lo que hay en el tag, no lo que hay en el árbol.** Si algo está a
   medias, va en una sección *Open* al final, no como si estuviera hecho.
6. **Si `VERSION`/`.version` está excluido por `.gitignore`** (habitual en repos que solo
   versionan markdown), la versión vive en el tag y en el README. Es correcto: el tag es
   inmutable y el fichero no.

**Estructura mínima de una entrada:**

```markdown
## [202610210041] — 2026-10-21 00:41

Tag `decisions-202610210041` · commit `479b44e` · **estado: no entregable, 36 páginas**

### Añadido
### Cambiado
### Corregido
### Decidido
```

Los cuatro apartados, y **`Decidido` es el importante**: no es un cambio en un fichero, es
una decisión que alguien tendrá que respetar después.

### Cuándo subir la versión

| Situación | ¿Nueva versión? |
|---|---|
| Cambia el contenido entregable | **Sí** |
| Cambia una decisión registrada | **Sí** |
| Solo notas de trabajo interno | No |
| Solo un commit de formato | No |

## Cómo añadir un módulo

1. Crea `modules/mi-modulo.mk`.
2. Documenta cada target con `##` y agrúpalos con `##@`.
3. Usa `$(call require_cmd,herramienta)` para validar dependencias.
4. Usa las variables `$(C_GREEN)`, `$(C_RED)`, etc. para los mensajes.

```makefile
##@ Mi grupo

.PHONY: mi-tarea
mi-tarea: ## Descripción que aparece en make help
	$(call require_cmd,mi-herramienta)
	@printf "$(C_GREEN)✓ Hecho.$(C_RESET)\n"
```

## Licencia

MIT.
