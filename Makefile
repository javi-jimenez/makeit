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
# PROJECT        ?= mi-sitio
# GIT_REMOTE     ?= origin
# GIT_BRANCH     ?= main
# FTP_SERVER     ?= ftp://ftp.example.org
# FTP_REMOTE_PATH?= /public_html/
# HUGO_VERSION   ?= 0.152.2

# Núcleo (obligatorio).
include $(MAKEIT)/makeit.mk

# --- Módulos (descomenta los que uses) -------------------------------------
include $(MAKEIT)/modules/git.mk
include $(MAKEIT)/modules/ftp.mk
include $(MAKEIT)/modules/hugo.mk
# include $(MAKEIT)/modules/test.mk
# include $(MAKEIT)/modules/docker.mk
# include $(MAKEIT)/modules/clean.mk
