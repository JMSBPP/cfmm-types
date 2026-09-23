# [TYPE:: TIME_SPACING](https://github.com/JMSBPP/cfmm-types/issues/15)

`-- types.toml: TimeSpacing` · domain **RealizedVolatility** · track [#26](https://github.com/JMSBPP/cfmm-types/issues/26)

\[
\begin{aligned}
\mathrm{TimeSpacing}
&\leftarrow
\bar{dt}
:=
\{dt \in \mathrm{u8} \mid dt \in \{2,3,4,5,6,8,9,10\}\}
\\[1em]
\mathrm{intro}
&::
\mathrm{u8} \to \mathrm{TimeSpacing} + \bot
\\
\mathrm{intro}(dt)
&=
\begin{cases}
\bar{dt} & \text{if } dt \in \mathrm{TimeSpacing} \\
\bot & \text{if } dt \notin \mathrm{TimeSpacing}
\end{cases}
\end{aligned}
\]

## Std / host reuse (#26)

| Candidate | Disposition |
|-----------|-------------|
| Extend `TimeSpacing` | **Reuse** — home for `sqrt_dt` + `SQRT_DT_RAY_*` |
| `Ray` | **Available** — [#28](https://github.com/JMSBPP/cfmm-types/issues/28)/[#32](https://github.com/JMSBPP/cfmm-types/issues/32) `cfmm_types::Ray` on develop |
| `Window` / `TimeIndex` / `n(dt)` | **Reject as home** — lattice, not \(\sqrt{dt}\cdot\mathrm{RAY}\) |
| WeinerGenerator Shock / DeltaW | **Reject** — stay in vol-markets; import from here |
| std math / sqrt / ray | **Reject** — none present |

## \(\mathrm{sqrt\_dt}\)

### \(\mathrm{sqrt\_dt}
::
\mathrm{TimeSpacing}(\bar{dt})
\to
\mathrm{Ray}\)

\[
\begin{aligned}
\mathrm{Eff}^{\mathrm{sqrt\_dt}} &= [\,]
\\
\mathrm{sqrt\_dt}(\bar{dt})
&=
\mathrm{intro}\bigl(\mathtt{SQRT\_DT\_RAY}_{\bar{dt}}\bigr)
\\
&=
\big\lfloor \sqrt{\bar{dt}}\,{\cdot}\,\mathrm{RAY} \big\rfloor
\\
\bar{dt} &\in \{2,3,4,5,6,8,9,10\}
\\
&\text{(comptime table; not }\mathtt{getSqrtRatioAtTick}\text{)}
\end{aligned}
\]

Plank: `sqrt_dt`. BTT: [TimeSpacingSqrtDt.btt](TimeSpacingSqrtDt.btt). Suite: `test/types/TimeSpacing.t.sol`. Harness: `test/harness/TimeSpacingHarness.plk` (`sqrtDt2`…`sqrtDt10` → `rayVal(sqrt_dt(dt))`).

## Export

`cfmm_types::TimeSpacing` — vol-markets WeinerGenerator pins `sqrt_dt` + table (replaces local `SQRT_DT_RAY_*` / `sqrt_dt_ray`).

