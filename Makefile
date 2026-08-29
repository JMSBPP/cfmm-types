.PHONY: plank-toolchain compile-plank clean-plank

PLANK := plank
PLANK_BACKEND := sona
PLANK_BUILD := build/plank
PLANK_PATH_BIN := $(HOME)/.plank/bin/plank
PLANK_DEV_EXEC := lib/plank-monorepo/plankc/target/release/plank

PLANK_DEP := --dep std=lib/plank-monorepo/std/ --dep types=src/types --dep lib=src/lib

plank-toolchain:
	cd lib/plank-monorepo/plankc && cargo build --release
	mkdir -p $(dir $(PLANK_PATH_BIN))
	ln -sf $(abspath $(PLANK_DEV_EXEC)) $(PLANK_PATH_BIN)

compile-plank:
	@mkdir -p $(PLANK_BUILD)
	@rc=0; ok=0; fail=0; skip=0; \
	for f in $$(grep -rlE '^[[:space:]]*init[[:space:]]*\{' --include='*.plk' src test 2>/dev/null | sort); do \
		out="$(PLANK_BUILD)/$$(echo "$$f" | tr / _ | sed 's/\.plk$$//').hex"; \
		printf '>> compiling %s\n' "$$f"; \
		if $(PLANK) build "$$f" $(PLANK_DEP) --backend '$(PLANK_BACKEND)' > "$$out" 2>"$$out.err"; then \
			rm -f "$$out.err"; printf '   OK   %s -> %s\n' "$$f" "$$out"; ok=$$((ok+1)); \
		else \
			rm -f "$$out"; printf '   FAIL %s -> %s.err\n' "$$f" "$$out"; fail=$$((fail+1)); rc=1; \
		fi; \
	done; \
	printf '\ncompile-plank: %s ok, %s failed, %s skipped\n' "$$ok" "$$fail" "$$skip"; \
	exit $$rc

clean-plank:
	@rm -rf $(PLANK_BUILD)
