# Type implementer:
#   just                  → compile every [[artifact]] in compile.toml
#   just plank <file.plk> → one file + deps (std, cfmm_types, lib), sona
default: compile-toml

plank file:
	plank build {{file}} --dep std=lib/plank-monorepo/std/ --dep cfmm_types=src/types --dep lib=src/lib --backend sona

compile-toml:
	bash scripts/compile-toml.sh
