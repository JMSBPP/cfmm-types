# [TYPE:: RAY](https://github.com/JMSBPP/cfmm-types/issues/28)

`-- types.toml: Ray` · domain **Numerics** · migrate draft `RayAlgebra`  
Independent of TimeSpacing \(\lfloor\sqrt{\bar{dt}}\,{\cdot}\,\mathrm{RAY}\rfloor\) ([#26](https://github.com/JMSBPP/cfmm-types/issues/26)).

\[
\begin{aligned}
\mathrm{RAY} &= 10^{27}
\\
\mathrm{Ray}
&\leftarrow
\{\,r \mid r.\mathrm{val} \in \mathrm{u256}\,\}
\\[1em]
\mathrm{intro}
&::
\mathrm{u256} \to \mathrm{Ray}
\\
\mathrm{rayVal}
&::
\mathrm{Ray} \to \mathrm{u256}
\\
\mathrm{rayMulId}
&::
() \to \mathrm{Ray}
\\
\mathrm{rayAddId}
&::
() \to \mathrm{Ray}
\\
\mathrm{rayMax}
&::
() \to \mathrm{Ray}
\\[1em]
\mathrm{Eff}^{\mathrm{Ray}} &= [\,]
\end{aligned}
\]

## Laws (type phase — holes)

\[
\begin{aligned}
\mathrm{rayVal}(\mathrm{intro}(x)) &= x
\\
\mathrm{rayMulId}() &= \mathrm{intro}(\mathrm{RAY\_UNIT})
\\
\mathrm{rayAddId}() &= \mathrm{intro}(\mathrm{RAY\_ZERO})
\\
\mathrm{rayMax}() &= \mathrm{intro}\bigl(\lfloor \mathrm{U256\_MAX}/\mathrm{RAY\_UNIT} \rfloor\bigr)
\\
\mathrm{RAY\_UNIT} &= 10^{27},\quad
\mathrm{RAY\_ZERO} = 0,\quad
\mathrm{RAY\_2} = 2\,{\cdot}\,10^{27}
\end{aligned}
\]

Deferred (not this slice): `Expansion` / `Contraction`, `ScaleFactor`, `scaleRay`.

## Std / host reuse

| Candidate | Disposition |
|-----------|-------------|
| Draft `RayAlgebra` → `src/types/Ray.plk` | **Migrate** |
| vol-markets `Numerics.RAY` | **Related** — scale constant only |
| Host Tick / Time* / Window | **Reject** |
| std math / Option | **Reject** — no Ray FP |
| TimeSpacing √ table | **Reject** — independent (#26) |

Plank: `cfmm_types::Ray::*`.  
**Holes this phase:** bodies for `intro`, `rayVal`, `rayMulId`, `rayAddId`, `rayMax` (define).
