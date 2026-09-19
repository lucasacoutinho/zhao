BEND ?= $(if $(wildcard $(CURDIR)/.tools/bend/bin/bend),$(CURDIR)/.tools/bend/bin/bend,bend)
VERSION := $(shell cat VERSION)
export BEND_NO_TELEMETRY := 1

.PHONY: setup check package publish

setup:
	sh scripts/install-bend.sh

check:
	"$(BEND)" src/zhao.bend
	"$(BEND)" src/PROOF.bend

package: check
	mkdir -p .build
	tar -czf ".build/zhao-$(VERSION).tar.gz" -C src .
	set -eu; \
	tmp="$$(mktemp -d)"; \
	trap 'rm -r -- "$$tmp"' EXIT; \
	tar -xzf ".build/zhao-$(VERSION).tar.gz" -C "$$tmp"; \
	test ! -e "$$tmp/.tools"; \
	test ! -e "$$tmp/.build"; \
	(cd "$$tmp" && "$(BEND)" zhao.bend); \
	(cd "$$tmp" && "$(BEND)" PROOF.bend)

publish: check
	BEND="$(BEND)" sh scripts/publish.sh
