# [TYPE:: PIPS](https://github.com/JMSBPP/cfmm-types/issues/27)

`-- types.toml: Pips` · domain **RealizedVolatility** · track [#27](https://github.com/JMSBPP/cfmm-types/issues/27)

\[
\begin{aligned}
\mathrm{PIPS}
&=
10^{6}
\quad\text{(Algebra FEE\_DENOMINATOR; }1\sigma\text{ scale)}
\\[1em]
\mathrm{Pips}
&::
\mathrm{type}
\\
\mathrm{Pips}
&=
\{\,\mathrm{val}:\mathrm{u16}\,\}
\\[1em]
\mathrm{intro}
&::
\mathrm{u256}\times\mathrm{u256}
\to
\mathrm{Pips}+\bot
\\
\mathrm{intro}(v_1,v_2)
&=
\begin{cases}
\mathrm{Pips}\{\mathrm{val}\leftarrow\mathrm{u16}(q)\}
&
\text{if }
q=\mathrm{mulDiv}(v_1,v_2,\mathrm{PIPS})
\text{ and }
q\in\mathrm{u16}
\\
\bot
&
\text{if }
q\notin\mathrm{u16}
\end{cases}
\\[1em]
\mathrm{mulDiv}(v_1,v_2,d)
&=
\big\lfloor (v_1\cdot v_2)/d \big\rfloor
\quad\text{(checked; }d=\mathrm{PIPS}\text{)}
\\[1em]
\mathrm{Eff}^{\mathrm{Pips}}
&=
[\,]
\end{aligned}
\]

## Std / host reuse (#27)

| Candidate | Disposition |
|-----------|-------------|
| `std::core::uint::u16` | **Reject as type** — width only |
| `std::option::Option` | **Reject** — not optional product |
| `std::core::ops::{checked_mul, checked_div_down}` | **Reuse as ops** — implement `mulDiv` |
| Host `Tick` / `TickSpacing` | **Reject** — tick lattice |
| Vol-markets `Numerics::PIPS` | **Reject as type** — scale constant; this module owns `PIPS` for lib export |
| Vol-markets `ShockPips` | **Reject** — signed mag sibling; stays in Weiner |
| `Ray` ([#28](https://github.com/JMSBPP/cfmm-types/issues/28)) | **Reject as carrier this phase** — future typed `sqrt_ray` input |

## IMPROVE (v1 inputs untyped)

> **NOTE:** v1 `intro` takes two **untyped** `u256` (`v_1` ≈ Ray-scale √, `v_2` ≈ shock magnitude).  
> This can be improved: tighten arguments to typed carriers (e.g. `Ray` × magnitude) once those tracks land. Do not invent dependent input kinds in this type phase.

## First define behavior (`.btt` later)

Planned tree (define phase — not this phase):

- **success:** `intro(v1,v2)` → `Pips { val }` when `mulDiv(v1,v2,PIPS)` fits `u16`
- **invalid:** product does not fit `u16` → revert

BTT path (define): [Pips.btt](Pips.btt) · suite `test/types/Pips.t.sol`

## Export

`cfmm_types::Pips` — vol-markets WeinerGenerator pins this for `(sqrt_ray, mag) → Pips` (replaces ad-hoc `checked_mul </ PIPS` product when define lands).
