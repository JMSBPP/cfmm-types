[MAIN](.spec/REALIZED_VOLATILITY.md)

\[
\begin{aligned}
	\mathrm{Window} = 24\times 60 \times 60
\end{aligned}
\]


[REF::`uint32 internal constant WINDOW = 1 days;`](node_modules/@cryptoalgebra/volatility-oracle-plugin/contracts/libraries/VolatilityOracle.sol)

```
uint32 internal constant WINDOW = 1 days;
├ Hex: 0x15180
├ Hex (full word): 0x0000000000000000000000000000000000000000000000000000000000015180
└ Decimal: 86400
```

\[
	\begin{aligned}
		(\mathrm{Window})^{-1}
	\end{aligned}
\]


\[
\begin{aligned}
	\mathrm{Window} = 24\times 60 \times 60
\end{aligned}
\]

\[
	\begin{aligned}
		\textrm{Window} = \sum_{i=0}^{N} \bar t_i \\
		\\
		N =\frac{\text{Window}}{\bar dt}
	\end{aligned}
\]


Oracle lattice \(\bar{dt}\) is the subset of TimeSpacing that divides \(W\) and fits one WINDOW in a `uint16` ring (drops \(1\) and \(7\)):

\[
\begin{aligned}
	\bar{dt} &\in \{2,3,4,5,6,8,9,10\} \\
	N &= W/\bar{dt} \in \mathbb{N} \\
	M &= 65536
\end{aligned}
\]

Entry points: [TimeIndex](../TimeIndex/TimeIndex.md).

\[
	\begin{aligned}
		\textrm{TimeWidth} \leftarrow n_t\,:= \{n_t \in \mathrm{u24}\mid 1\leq n_t \leq \lfloor \, \rfloor\} \\
		\\
		\text{TimeCoordinate}\, \leftarrow t (t_{\mathrm{init}} \in \textrm{u32}, \bar{dt}, n_t) := \{t \mid t = t_{\mathrm{init}} + n_t \, \bar{dt}\} \, 
	\end{aligned}
\]

\[
	\begin{aligned}
		\textrm{TimeSequence} \leftarrow T(\bar{dt}) := \{\{t_j\}_{j=0}^{N = \frac{\mathrm{Window}}{\bar{dt}}} \,  \mid \, \textrm{Window} = \sum_{i=0}^{N} \bar{dt}\}
	\end{aligned}
\]

\[
    \begin{aligned}
		i(t)
		&=
		\lfloor (t-t_{\mathrm{init}})/\bar{dt} \rfloor \bmod M
		\\
		\mathrm{lastIndex}(t) &= i(t)
		\\
		\mathrm{oldestIndex}(t)
		&=
		\begin{cases}
		0 & \lfloor (t-t_{\mathrm{init}})/\bar{dt} \rfloor < M \\
		(i(t)+1)\bmod M & \text{otherwise}
		\end{cases}
		\\
		\mathrm{windowStartIndex}(t) &= (i(t)-N)\bmod M
 	\end{aligned}
\]

\[
	\begin{aligned}
		\mathrm{TimePeriod}\, \leftarrow \, k \in \{0,\ldots,N\} \\
		\texttt{secondsAgo} = k\cdot\bar{dt} \\
		\text{target bin} = (i(t)-k)\bmod M
	\end{aligned}
\]

`getSingleTimepoint` allows \(k=0\) (now). `getTwapTick` rejects \(k=0\).

uint32 clock wrap is not this lattice — [`typed-evm-semantics`](https://github.com/JMSBPP/typed-evm-semantics).



# How is it used on REF ?

TimePoint \((t) = \{ \sigma (t), i(t), i_{\mu} (t) \cdots\}\)

TimeContainer = TimePoint[UINT16_MODULO]

The library defines an index `windowStartIndex`

```
uint16 windowStartIndex; // closest timepoint lte WINDOW seconds ago (or oldest timepoint), _should be used only from last timepoint_!
```

> This implies that WINDOW role is being a upper bound

- `windowStartIndex` 

Provides means to interact with:
                                                                  Number of seconds in the past to start calculating time-weighted average
///   getTwapTick(uint32,int24,uint32)            → 0x1a72d0df  (period, tick, time)
///   initializeTWAP(uint32,int24)                → 0xed64c40a  (timestamp, tick)
///   writeTimepoint(uint32,int24)                → 0xb09b2297  (timestamp, tick) 
///   canGetTwap(uint32,uint32)                   → 0x4a513c98  (period, timestamp)
e///   getSingleTimepoint(uint32,uint32,int24)     → 0xf1a0ebe5  (secondsAgo, timestamp, tick)
///   getTimepoints(uint32[],uint32,int24)        → 0x36ab33e3  (secondsAgo[],timestamp,tick)
///   getAverageVolatilityLast(uint32,int24)      → 0x59dc9384  (timestamp, lastIndex, oldestIndex,tick)


  function getTwapTick(uint32 period, int24 currentTick, uint32 currentTime) external view returns (int24 timeWeightedAverageTick) {
    require(period != 0, 'Period is zero');
	
VolatilityOracle.Timepoint memory current = layout.timepoints.getSingleTimepoint(currentTime, 0, currentTick, lastIndex, oldestIndex);

VolatilityOracle.Timepoint memory old = layout.timepoints.getSingleTimepoint(currentTime, period, currentTick, lastIndex, oldestIndex) {
	uint32 target = time - secondsAgo;

}
