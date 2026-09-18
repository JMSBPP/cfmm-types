import [TimeStamp](@.spec/Timestamp/Timestamp.md)



\[
	\begin{aligned}
		U_{32} = 4294967295 \\
		\\
		\textrm{TimeWidth} \leftarrow n_t (t_0,\bar{dt})\,:= \{n_t \in \mathrm{u24}\mid n_t (t_0, t_0 - U_{32})\leq n_t \leq \lfloor \,\frac{t_0 - U_{32}}{\bar{dt}} \rfloor\} 	\end{aligned}
\]
- dt max is t_0 - U_{32}
 
