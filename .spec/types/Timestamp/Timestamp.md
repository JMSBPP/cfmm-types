# TYPE:: TIMESTAMP

Clock instant. Not a lattice node (`TimeIndex` / `TimeCoordinate`), not a duration (`secondsAgo` / `TimePeriod`), not a sample (`TimePoint`).

Idris: [Timestamp.idr](./Timestamp.idr). EVM observation (TIMESTAMP, ABI packing, wrapping `SUB`) is not this module — file it on [`JMSBPP/typed-evm-semantics`](https://github.com/JMSBPP/typed-evm-semantics).

\[
\begin{aligned}
U_{32}
&=
4294967295
\\[1em]
\mathrm{Timestamp}
&\leftarrow
t_0
:=
\{ t \in \mathrm{u256} \mid t \le U_{32} \}
\\[1em]
\mathrm{intro}
&::
\mathrm{u256} \to \mathrm{Timestamp} + \bot
\\
\mathrm{intro}(t)
&=
\begin{cases}
t_0 & \text{if } t \in \mathrm{Timestamp} \\
\bot & \text{if } t \notin \mathrm{Timestamp}
\end{cases}
\\[1em]
\mathrm{elim}
&::
\mathrm{Timestamp} \to \mathrm{u32}
\\
\mathrm{elim}(t_0)
&=
t_0
\\[1em]
\mathrm{ago}
&::
\mathrm{Timestamp} \times \mathrm{u32} \to \mathrm{Timestamp} + \bot
\\
\mathrm{ago}(t_0,\delta)
&=
\begin{cases}
t_0 - \delta & \text{if } \delta \le \mathrm{elim}(t_0) \\
\bot & \text{otherwise}
\end{cases}
\\[1em]
(\le)
&::
\mathrm{Timestamp} \times \mathrm{Timestamp} \to \mathbf{2}
\end{aligned}
\]
