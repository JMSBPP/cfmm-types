plank:
	plank build test/harness/TickHarness.plk \
	--dep std=lib/plank-monorepo/std/ \
	--dep cfmm_types=src/types/

test-set-tick:
	forge test --match-test test__unit__setTick -vvv
