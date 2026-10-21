# =============================================================================
# makeit — módulo git
# -----------------------------------------------------------------------------
# Tareas habituales de git: estado, commit, push, pull, tags, releases.
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   GIT_REMOTE    remoto por defecto (default: origin)
#   GIT_REMOTES   espacies-separados; remotos para `push-all` y `push-tags`
#                 (ej: GIT_REMOTES="origin gitea"). Si está vacío se usa GIT_REMOTE.
#   GIT_BRANCH    rama por defecto (default: main)
#   COMMIT_MSG    mensaje de commit por defecto
# La versión del proyecto (para los tags) sale de ./VERSION (ver `make version`).
# =============================================================================

# Remotos a los que empujan los targets "multi" (`push-all`, `push-tags`).
# Ejemplo de uso real (repo replicado GitHub + Gitea): GIT_REMOTES="origin gitea"
GIT_REMOTES ?=

# Remotos "lentos": su almacén no soporta packs grandes. El caso real es un
# Gitea cuyo directorio de repositorios vive en s3fs: al descomprimir el pack
# escribe un tmp-pack en un FS sin locking y el push falla con
#   "remote unpack failed: index-pack abnormal exit"
# Empatar con el nombre del remoto o con cualquier trozo de su URL.
#
# Hay dos grupos porque `git -c` es una opción GLOBAL (antes del subcomando) y
# `--no-thin` es una opción DE PUSH (después). Con todo en una variable se
# acaba llamando a `git push -c ...`, que git rechaza con el texto de ayuda.
GIT_SLOW_REMOTES   ?=
GIT_SLOW_GIT_OPTS  ?= -c pack.threads=1
GIT_SLOW_PUSH_OPTS ?= --no-thin

# Devuelve "<opciones globales>|<opciones de push>" para el remoto $1.
# Compara contra el nombre y contra la URL, así que vale GIT_SLOW_REMOTES=gitea
# tanto si el remoto se llama "gitea" como si apunta a gitea.dominio.tld.
# Sin remotos lentos devuelve "|" (ambas partes vacías).
#
# OJO: la receta evita `case ... )` a propósito. Un paréntesis de cierre dentro
# de un `$(call ...)` cierra la función de make y rompe la expansión.
define remote_push_flags
$(if $(strip $(GIT_SLOW_REMOTES)), \
	__u=$$(git remote get-url "$(1)" 2>/dev/null); \
	__m=""; \
	for __s in $(GIT_SLOW_REMOTES); do \
		printf '%s %s' "$(1)" "$$__u" | grep -q -- "$$__s" && { __m=1; break; }; \
	done; \
	if [ -n "$$__m" ]; then echo "$(GIT_SLOW_GIT_OPTS)|$(GIT_SLOW_PUSH_OPTS)"; else echo "|"; fi,|
)
endef

# =============================================================================
##@ Git
# =============================================================================

.PHONY: git-status
git-status: ## Muestra el estado de git
	$(call require_cmd,git)
	@git status --short --branch

.PHONY: git-commit
git-commit: ## Hace commit de todos los cambios (COMMIT_MSG="...")
	$(call require_cmd,git)
	@git add -A; \
	if git diff --cached --quiet; then \
		printf "$(C_YELL)• Sin cambios que commitear.$(C_RESET)\n"; \
	else \
		git commit -m "$(COMMIT_MSG)"; \
		printf "$(C_GREEN)✓ Commit creado.$(C_RESET)\n"; \
	fi

.PHONY: push
push: ## Hace commit de todo y push a GIT_REMOTE/GIT_BRANCH
	$(call require_cmd,git)
	@$(MAKE) git-commit
	@f=$$($(call remote_push_flags,$(GIT_REMOTE))); \
	git $${f%%|*} push $${f#*|} "$(GIT_REMOTE)" "$(GIT_BRANCH)"
	@printf "$(C_GREEN)✓ Subido a $(GIT_REMOTE)/$(GIT_BRANCH).$(C_RESET)\n"

.PHONY: pull
pull: ## Hace pull de GIT_REMOTE/GIT_BRANCH
	$(call require_cmd,git)
	@git pull "$(GIT_REMOTE)" "$(GIT_BRANCH)"
	@printf "$(C_GREEN)✓ Actualizado desde $(GIT_REMOTE)/$(GIT_BRANCH).$(C_RESET)\n"

# Push a VARIOS remotos (espejo). Útil cuando el repo vive en dos forjas
# (p. ej. GitHub + Gitea): un solo commit, N empujes, y el fallo de uno no
# impide intentar los demás ni oculta el error.
.PHONY: push-all
push-all: ## Hace commit y push a todos los remotos de GIT_REMOTES
	$(call require_cmd,git)
	@$(MAKE) --no-print-directory git-commit
	@remotes="$(if $(GIT_REMOTES),$(GIT_REMOTES),$(GIT_REMOTE))"; \
	fail=0; \
	for r in $$remotes; do \
		printf "  $(C_CYAN)%-10s$(C_RESET) → " "$$r"; \
		f=$$($(call remote_push_flags,$$r)); \
		out=$$(git $${f%%|*} push $${f#*|} "$$r" "$(GIT_BRANCH)" 2>&1); rc=$$?; \
		if [ $$rc -eq 0 ]; then \
			printf "$(C_GREEN)✓$(C_RESET)\n"; \
		else \
			printf "$(C_RED)✗$(C_RESET)\n"; printf "%s\n" "$$out" | sed 's/^/    /'; fail=1; \
		fi; \
	done; \
	if [ $$fail -eq 0 ]; then \
		printf "$(C_GREEN)✓ Subido a todos los remotos.$(C_RESET)\n"; \
	else \
		printf "$(C_RED)✗ Algún remoto falló (ver arriba).$(C_RESET)\n"; exit 1; \
	fi

# Etiqueta con timestamp: <version>-YYYYMMDDHHMM (ej: 1.0.1-202610082159).
# La versión sale de ./VERSION (ver `make version`). Si no hay VERSION, solo
# se usa el timestamp.
#
# Antes de crear el tag, si CHANGELOG_AUTO != 0, garantiza que existe la entrada
# de la versión en CHANGELOG.md y **la commitea**. Sin ese commit la entrada
# quedaría fuera del tag, y el CHANGELOG debe describir lo que hay EN el tag.
.PHONY: tag
tag: ## Crea un tag <version>-<timestamp> (versión de ./VERSION)
	$(call require_cmd,git)
	@stamp=$$(date +%Y%m%d%H%M); \
	ver="$(PROJECT_VERSION)"; \
	if [ -n "$$ver" ] && [ "$$ver" != "0.0.0" ]; then tag="$$ver-$$stamp"; else tag="$$stamp"; fi; \
	if git rev-parse "$$tag" >/dev/null 2>&1; then \
		printf "$(C_YELL)• El tag $$tag ya existe.$(C_RESET)\n"; \
	else \
		if [ "$(CHANGELOG_AUTO)" != "0" ] && [ -n "$$ver" ] && [ "$$ver" != "0.0.0" ]; then \
			if ! grep -qF "## [$$ver]" "$(CHANGELOG_FILE)" 2>/dev/null; then \
				$(MAKE) --no-print-directory changelog-new >/dev/null 2>&1 || true; \
			fi; \
			if [ -n "$$(git status --porcelain -- "$(CHANGELOG_FILE)" 2>/dev/null)" ]; then \
				git add "$(CHANGELOG_FILE)"; \
				git commit -q -m "changelog: entrada $$ver (antes del tag)" -- "$(CHANGELOG_FILE)"; \
				printf "$(C_YELL)• Entrada $$ver commiteada en $(CHANGELOG_FILE) — rellénala.$(C_RESET)\n"; \
			fi; \
		fi; \
		git tag -a "$$tag" -m "Release $$tag"; \
		printf "$(C_GREEN)✓ Tag $$tag creado.$(C_RESET)\n"; \
	fi

.PHONY: push-tags
push-tags: ## Sube los tags a todos los remotos de GIT_REMOTES
	$(call require_cmd,git)
	@remotes="$(if $(GIT_REMOTES),$(GIT_REMOTES),$(GIT_REMOTE))"; \
	fail=0; \
	for r in $$remotes; do \
		printf "  $(C_CYAN)%-10s$(C_RESET) → " "$$r"; \
		f=$$($(call remote_push_flags,$$r)); \
		out=$$(git $${f%%|*} push $${f#*|} "$$r" --tags 2>&1); rc=$$?; \
		if [ $$rc -eq 0 ]; then \
			printf "$(C_GREEN)✓$(C_RESET)\n"; \
		else \
			printf "$(C_RED)✗$(C_RESET)\n"; printf "%s\n" "$$out" | sed 's/^/    /'; fail=1; \
		fi; \
	done; \
	[ $$fail -eq 0 ] || printf "$(C_RED)✗ Algún remoto rechazó los tags.$(C_RESET)\n"

# Tag + subida en un paso. Es el `release` que documentaba el README y faltaba.
.PHONY: release
release: ## Crea el tag y lo sube a GIT_REMOTES
	@$(MAKE) --no-print-directory tag
	@$(MAKE) --no-print-directory push-tags

# Hooks de git. Prefiere el instalador del proyecto (que puede hacer más cosas
# que copiar ficheros) y, si no existe, usa core.hooksPath sobre .githooks/.
.PHONY: install-hooks
install-hooks: ## Instala los git hooks (.githooks/ o tools/install-git-hooks.sh)
	$(call require_cmd,git)
	@if [ -x tools/install-git-hooks.sh ]; then \
		printf "$(C_CYAN)▶ tools/install-git-hooks.sh$(C_RESET)\n"; \
		tools/install-git-hooks.sh; \
	elif [ -d .githooks ]; then \
		git config core.hooksPath .githooks; \
		printf "$(C_GREEN)✓ core.hooksPath = .githooks$(C_RESET)\n"; \
	else \
		printf "$(C_YELL)• No hay tools/install-git-hooks.sh ni .githooks/.$(C_RESET)\n"; \
	fi
