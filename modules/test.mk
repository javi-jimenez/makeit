# =============================================================================
# makeit — módulo test
# -----------------------------------------------------------------------------
# Ejecuta tests detectando automáticamente el runner del proyecto, o usando
# el comando que definas en TEST_CMD.
# Variables (sobreescribibles en el Makefile del proyecto o .env):
#   TEST_CMD   comando de test explícito (tiene prioridad sobre la detección)
# =============================================================================

# =============================================================================
##@ Test
# =============================================================================

.PHONY: test
test: ## Ejecuta los tests (TEST_CMD o autodetección)
	@if [ -n "$(TEST_CMD)" ]; then \
		printf "$(C_CYAN)▶ $(TEST_CMD)$(C_RESET)\n"; \
		$(TEST_CMD); \
	elif [ -f pytest.ini ] || [ -f pyproject.toml ] || [ -f setup.py ]; then \
		printf "$(C_CYAN)▶ pytest$(C_RESET)\n"; \
		python -m pytest; \
	elif [ -f package.json ]; then \
		printf "$(C_CYAN)▶ npm test$(C_RESET)\n"; \
		npm test; \
	elif [ -f go.mod ]; then \
		printf "$(C_CYAN)▶ go test$(C_RESET)\n"; \
		go test ./...; \
	elif [ -f Cargo.toml ]; then \
		printf "$(C_CYAN)▶ cargo test$(C_RESET)\n"; \
		cargo test; \
	elif [ -f Makefile.test ]; then \
		printf "$(C_CYAN)▶ make -f Makefile.test$(C_RESET)\n"; \
		$(MAKE) -f Makefile.test; \
	else \
		printf "$(C_YELL)• No se detectó ningún runner de tests. Define TEST_CMD.$(C_RESET)\n"; \
	fi

.PHONY: lint
lint: ## Ejecuta el linter (LINT_CMD)
	@if [ -n "$(LINT_CMD)" ]; then \
		printf "$(C_CYAN)▶ $(LINT_CMD)$(C_RESET)\n"; \
		$(LINT_CMD); \
	else \
		printf "$(C_YELL)• Define LINT_CMD para usar este target.$(C_RESET)\n"; \
	fi
