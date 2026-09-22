# TYPE:: TIME_INDEX

[WINDOW](../WINDOW/WINDOW.md) · [TimeSpacing](../TimeSpacing/TimeSpacing.md)

`@evm_timestamp` is a value. Indices are derived. Algebra `lastIndex+1` occupancy is **not** this lattice.

\[
\begin{aligned}
\bar{dt}
&\in \{2,3,4,5,6,8,9,10\}
\\
W &= 86400
\\
N &= W/\bar{dt}
\\
M &= 65536
\\
t_{\mathrm{init}}
&=
\texttt{initialize}(\textit{time})
\\
t
&=
\texttt{@evm\_timestamp}
\quad\text{(u32-truncated value)}
\\[1em]
i(t)
&=
\bigl\lfloor (t-t_{\mathrm{init}})/\bar{dt} \bigr\rfloor \bmod M
\\
t_i
&=
t_{\mathrm{init}} + i\cdot\bar{dt}
\quad\text{(one wrap)}
\\[1em]
\mathrm{lastIndex}(t)
&=
i(t)
\\[0.75em]
\mathrm{wrapped}(t)
&\iff
\bigl\lfloor (t-t_{\mathrm{init}})/\bar{dt} \bigr\rfloor \ge M
\\
\mathrm{oldestIndex}(t)
&=
\begin{cases}
0 & \neg\mathrm{wrapped}(t) \\
(i(t)+1)\bmod M & \mathrm{wrapped}(t)
\end{cases}
\\[0.75em]
\mathrm{windowStartIndex}(t)
&=
(i(t)-N)\bmod M
\\[1em]
\mathrm{next}
&::
i \mapsto (i+1)\bmod M
\end{aligned}
\]

Overflows:

- **window** — lookback \(k=N\), index \(i-N\). Period \(W < M\cdot\bar{dt}\).
- **ring** — clock wrap at \(M\cdot\bar{dt}\) (\(\ge 131072\,\mathrm{s}\)). `oldestIndex` leaves \(0\) when \(\mathrm{wrapped}(t)\), even if that slot was never rewritten.
- **u32 clock** — not this module; [`typed-evm-semantics`](https://github.com/JMSBPP/typed-evm-semantics).

Holes stay uninitialized; a search may walk from `windowStartIndex` to the closest occupied slot \(\le t-W\).
