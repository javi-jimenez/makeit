# =============================================================================
# makeit — módulo ftp
# -----------------------------------------------------------------------------
# Subida de ficheros por FTP/SFTP usando lftp (mirror --reverse).
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   FTP_SERVER       host o URL (ej: ftp://ftp.example.org)   [obligatorio]
#   FTP_USERNAME     usuario                                  [obligatorio]
#   FTP_PASSWORD     contraseña                               [obligatorio]
#   FTP_REMOTE_PATH  ruta remota destino (default: /)
#   FTP_LOCAL_DIR    directorio local a subir (default: public)
#   FTP_DELETE       si vale 1, borra en remoto lo que no exista en local
#   FTP_VERBOSE      si vale 1, muestra cada fichero transferido
# =============================================================================

FTP_REMOTE_PATH ?= /
FTP_LOCAL_DIR   ?= public
FTP_DELETE      ?= 0
FTP_VERBOSE     ?= 0

# =============================================================================
##@ FTP
# =============================================================================

# Comprobación interna de requisitos.
.PHONY: _ftp-check
_ftp-check:
	$(call require_cmd,lftp)
	@test -n "$(FTP_SERVER)"   || { printf "$(C_RED)✗ Define FTP_SERVER.$(C_RESET)\n"; exit 1; }
	@test -n "$(FTP_USERNAME)" || { printf "$(C_RED)✗ Define FTP_USERNAME.$(C_RESET)\n"; exit 1; }
	@test -n "$(FTP_PASSWORD)" || { printf "$(C_RED)✗ Define FTP_PASSWORD.$(C_RESET)\n"; exit 1; }
	@test -d "$(FTP_LOCAL_DIR)" || { printf "$(C_RED)✗ No existe el directorio local '$(FTP_LOCAL_DIR)'.$(C_RESET)\n"; exit 1; }

.PHONY: ftp-upload
ftp-upload: _ftp-check ## Sube FTP_LOCAL_DIR por FTP a FTP_REMOTE_PATH
	@printf "$(C_CYAN)▶ Subiendo $(FTP_LOCAL_DIR)/ → $(FTP_SERVER)$(FTP_REMOTE_PATH)$(C_RESET)\n"
	@lftp -u "$(FTP_USERNAME),$(FTP_PASSWORD)" "$(FTP_SERVER)" -e \
		"set ftp:passive-mode true; \
		 set ftp:ssl-allow no; \
		 mirror --reverse $(if $(filter 1,$(FTP_VERBOSE)),--verbose,) \
		 $(if $(filter 1,$(FTP_DELETE)),--delete,) \
		 $(FTP_LOCAL_DIR)/ $(FTP_REMOTE_PATH); bye"
	@printf "$(C_GREEN)✓ Subida completada.$(C_RESET)\n"

.PHONY: ftp-dry-run
ftp-dry-run: _ftp-check ## Simula la subida FTP (sin transferir)
	@lftp -u "$(FTP_USERNAME),$(FTP_PASSWORD)" "$(FTP_SERVER)" -e \
		"set ftp:passive-mode true; \
		 mirror --reverse --dry-run --verbose \
		 $(FTP_LOCAL_DIR)/ $(FTP_REMOTE_PATH); bye"
