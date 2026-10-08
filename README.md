# makeit

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
| `makeit.mk` (core) | `help`, `version` |
| `modules/git.mk` | `push`, `pull`, `git-status`, `git-commit`, `tag`, `release` |
| `modules/ftp.mk` | `ftp-upload`, `ftp-dry-run` |
| `modules/hugo.mk` | `build`, `serve`, `clean`, `deploy`, `hugo-install` |
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
| `GIT_BRANCH` | `main` | Rama git |
| `COMMIT_MSG` | `Automated commit by makeit` | Mensaje de commit |
| `FTP_SERVER` | — | Host/URL FTP |
| `FTP_USERNAME` | — | Usuario FTP |
| `FTP_PASSWORD` | — | Contraseña FTP |
| `FTP_REMOTE_PATH` | `/` | Ruta remota destino |
| `FTP_LOCAL_DIR` | `public` | Directorio local a subir |
| `HUGO_VERSION` | `0.152.2` | Versión de Hugo |

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
