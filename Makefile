# =============================================================================
# Makefile de ejemplo — proyecto que usa makeit
# -----------------------------------------------------------------------------
# Copia este fichero a tu proyecto y descomenta los módulos que necesites.
#
# IMPORTANTE: define las variables del proyecto ANTES de los `include` para
# que sobreescriban los valores por defecto de makeit.
# =============================================================================

# Ruta a makeit (ajústala o defínela en tu .env).
MAKEIT ?= $(HOME)/data/repo/makeit

# --- Configuración específica del proyecto (antes de los include) ----------
PROJECT        ?= makeit
GIT_REMOTE     ?= origin
GIT_BRANCH     ?= main

# Réplica: GitHub (origin) + Gitea (gitea). Este repo se usa desde la propia
# máquina, así que aquí sí se puede incluir makeit desde su ruta (un proyecto
# cualquiera no debería: ataría su build a este HOME).
GIT_REMOTES      ?= origin gitea
GIT_SLOW_REMOTES ?= gitea

# Núcleo (obligatorio).
include $(MAKEIT)/makeit.mk

# --- Módulos (descomenta los que uses) -------------------------------------
include $(MAKEIT)/modules/git.mk
include $(MAKEIT)/modules/ftp.mk
include $(MAKEIT)/modules/hugo.mk
# include $(MAKEIT)/modules/test.mk
# include $(MAKEIT)/modules/docker.mk
# include $(MAKEIT)/modules/clean.mk
