# Type implementer entry: `just plank src/types/Foo.plk`
plank file:
	plank build {{file}} --dep std=lib/plank-monorepo/std/ --dep types=src/types --dep lib=src/lib --backend sona

compile-toml:
	bash scripts/compile-toml.sh
