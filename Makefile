BEND ?= $(if $(wildcard $(CURDIR)/.tools/bend/bin/bend),$(CURDIR)/.tools/bend/bin/bend,bend)
VERSION := $(shell cat VERSION)
export BEND_NO_TELEMETRY := 1

.PHONY: setup check cli-check native-cli-check test native-test package publish

setup:
	sh scripts/install-bend.sh

check:
	"$(BEND)" src/zhao.bend
	"$(BEND)" src/PROOF.bend

cli-check: check
	BEND="$(BEND)" sh scripts/test-cli.sh bend

native-cli-check: check
	mkdir -p .build
	"$(BEND)" examples/greet.bend -o .build/greet
	"$(BEND)" examples/forge.bend -o .build/forge
	sh scripts/test-cli.sh native

test: cli-check
	"$(BEND)" tests/main.bend

native-test: native-cli-check
	"$(BEND)" tests/main.bend -o .build/parser-tests
	.build/parser-tests --threads 1 > .build/native-1.txt
	.build/parser-tests --threads 4 > .build/native-4.txt
	cmp .build/native-1.txt .build/native-4.txt
	tail -n 4 .build/native-1.txt

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
