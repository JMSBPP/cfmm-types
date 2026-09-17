
## **WeinerGenerator**

 \(\Delta W (t_i) = \sqrt{\bar dt} \, \cdot\, \epsilon \, (t_i); \quad \epsilon (t_i) \sim \mathcal{N} \, (0,1)\)
 
- \(\epsilon (t_i) := \)shockPips ::Timestamp -> Pips
- sqrt{dt} -> u32 e -> u16 --> u48

Now given:

\[
	\begin{aligned}
		\underbrace{\Delta W (t_j)}_{\text{u40}} = \underbrace{\sqrt{\bar dt}}_{\text{u32}} \, \cdot \underbrace{\epsilon (t_i)}_{\text{u16}}
	\end{aligned}
\]
> This is because it does not the dt term never reaches extreme values of u32 and the sqrt smooths them and u16 is pips which are also bounded. This is still an optimistic approx



# MODEL

Consider a net-flow numeriare diffusion as:

\[
	\begin{aligned}
		\Delta Q_{M} (t_j) &= \frac{d\, \Delta Q_{M} (t_j)}{\bar dt} \, \Delta Q_{M} (t_{j-1}):: T_{Q} \{\text{base} = \textrm{RAY}\, \vee \, \textrm{WAD} \cdots\}\\
		\frac{d\, \Delta Q_{M} (t_j)}{\bar dt} \, &= \mu_F \, \bar dt \, + \, \sigma_{F} \, \Delta W (t_j):: T_{r}
	\end{aligned}
\]
 
Let's take as the canonical example RAY:

\[
	\begin{aligned}
		\text{RAY} := 10^{27}
	\end{aligned}
\]
Define  \(T_r (T_Q):= \text{ScalingFactor} (T_Q)\), and make the split:

\[
	\begin{aligned}
		\text{ExpansionFactor} (T_Q):= t::T_Q \mid t :: [\text{Id} (T_Q), \text{Max} (T_Q)] \\
		\text{ContractionFactor} (T_Q) := t::T_Q \mid t :: [0, \text{Id} (T_Q)]
	\end{aligned}
\]


Then:

\[
	\begin{aligned}
		T_r (T_Q, \text{Flag},n \in N_{256}) : \text{Expansion} \cup \text{Contraction}\times n \in N_{256} \to  T_r (T_Q)
	\end{aligned}
\]


Let's take as the canonical example RAY:

\[
	\begin{aligned}
		\text{RAY} := 10^{27}
	\end{aligned}
\]


\[
	\begin{aligned}
		T_Q (T_r) = T_r \cdot T_Q 
	\end{aligned}
\]

From
Make:

\[
	T_r = T_{r1} + T_{r2}
\]

And:

\[
	\begin{aligned}
		T_{r2} \leftarrow \sigma_F \, \cdot \, \Delta W (t_j)
	\end{aligned}
\]

Semantically \(\sigma_F\) is flow volatility

\[
	\sigma_F = 1/T \sum (T_Q - T_Q^*)^2
\]




Well consider the following case:


In this case 
But:

\[
	\begin{aligned}
		r_{j-1,j}\equiv\frac{\Delta Q_{M} (t_j)}{\Delta Q_{M} (t_{j-1})} = \frac{d\, \Delta Q_{M} (t_j)}{\bar dt}
	\end{aligned}
\]

For convenience since we are using the erc20 interface the total supply is the adjusted amount

Now we must concern with the interest rate model design:

> This is a [ref impl](lib/euler-vault-kit/src/Synths/EulerSavingsRate.sol)
```
struct ESRSlot {
    uint40 lastInterestUpdate;
    uint40 interestSmearEnd;
    uint168 interestLeft;
    uint8 locked;
}

...
function interestAccruedFromCache(ESRSlot memory esrSlotCache) internal view returns (uint256) {
    // If distribution ended, full amount is accrued
    if (block.timestamp >= esrSlotCache.interestSmearEnd) {return esrSlotCache.interestLeft;}
    // If just updated return 0
    if (esrSlotCache.lastInterestUpdate == block.timestamp) {return 0;}
        // Else return what has accrued
        uint256 totalDuration = esrSlotCache.interestSmearEnd - esrSlotCache.lastInterestUpdate;
        uint256 timePassed = block.timestamp - esrSlotCache.lastInterestUpdate;

        return esrSlotCache.interestLeft * timePassed / totalDuration;
    }
```


\(M\): \(T_{E20}\)

\[
	\begin{aligned}
		T_{E4626}:T_{E20} \to T_{E20}
	\end{aligned}
\]

Then net-flow numeriare diffusion is equivalent to interest rate difussion model

since flow characteristics are fixed we regard this type as a linear discrete time control system





