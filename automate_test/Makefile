.PHONY: setup test-api test-e2e test-mobile test-all report perf clean

setup:
	bash scripts/setup.sh

test-api: setup
	./run.sh api

test-e2e: setup
	./run.sh e2e

test-mobile: setup
	./run.sh mobile

test-all: setup
	./run.sh all

report:
	@echo "HTML: reports/html/report.html"
	@xdg-open reports/html/report.html 2>/dev/null || open reports/html/report.html 2>/dev/null || echo "open manually: reports/html/report.html"

perf:
	./run.sh perf

clean:
	rm -rf reports/html reports/coverage reports/junit.xml .pytest_cache
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true
