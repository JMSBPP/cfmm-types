\[
	\begin{aligned}
		\textrm{Tick} (\textrm{TickSpacing} , T (\textrm{TickSpacing})) \, \in \{1, \cdots 200\} \\
		T :=  \textrm{LegStep} (\textrm{TickSpacing})\mid \cdots \\

	 \end{aligned}
	
\]

> * Inside the constructor the LegStep proxied to the closest value that achieves its obecjtive

As an example consider a tick 160 with tick spacing of 40, then define:
x
\[
	\begin{aligned}
		\textrm{max}  (\textrm(TickSpacing)) = mul(floor(UINT24_{MAX}, tickSpacing), tickSpacing) \\
		\textrm{min} (\textrm(TickSpacing)) = mul(floor(INT24_{MIN}, tickSpacing), tickSpacing)
	\end{aligned}
\]


