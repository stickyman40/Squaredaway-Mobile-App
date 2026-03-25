.PHONY: help preflight ci ui-tests clean-local supabase-reset supabase-push

help:
	@echo "Available targets:"
	@echo "  make preflight       Run lightweight repo checks"
	@echo "  make ci              Run local CI sequence"
	@echo "  make ui-tests        Run local UI tests"
	@echo "  make clean-local     Remove generated local artifacts"
	@echo "  make supabase-reset  Reset local Supabase from migrations"
	@echo "  make supabase-push   Push migrations to linked Supabase project"

preflight:
	./scripts/preflight-check.sh

ci:
	./scripts/ci-local.sh

ui-tests:
	./scripts/ui-tests-local.sh

clean-local:
	./scripts/clean-local.sh

supabase-reset:
	./scripts/supabase-reset-local.sh

supabase-push:
	./scripts/supabase-push-remote.sh
