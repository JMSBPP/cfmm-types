-- Progress mirrors Timestamp.md: set + intro + elim + ago + (≤).
-- Carrier: U256 = Integer (no Bits256 in Idris2 prelude).
-- U32    = Bits32 (EVM u32 width; Cast Integer Bits32 wraps mod 2^32).
-- intro's So is a run-time Boolean test (Data.So). TIMESTAMP / word / wrapping
-- SUB are EVM observations — file those on JMSBPP/typed-evm-semantics, not here.
module Timestamp

import Data.So

------------------------------------------------------------------------
-- Bounds
------------------------------------------------------------------------

public export
U32max : Integer
U32max = 4294967295

------------------------------------------------------------------------
-- Carrier: u256 ≅ Integer; u32 ≅ Bits32
------------------------------------------------------------------------

public export
U256 : Type
U256 = Integer

public export
toU256 : Nat -> U256
toU256 = cast

public export
fromU256 : U256 -> Integer
fromU256 t = t

public export
U32 : Type
U32 = Bits32

public export
toU32 : Integer -> U32
toU32 = cast

public export
fromU32 : U32 -> Integer
fromU32 = cast

------------------------------------------------------------------------
-- Timestamp ← t₀ := { t ∈ u256 | 0 ≤ t ≤ U32max }
------------------------------------------------------------------------

public export
inTimestamp : U256 -> Bool
inTimestamp t = t >= 0 && t <= U32max

public export
Timestamp : Type
Timestamp = (t : U256 ** So (inTimestamp t))

------------------------------------------------------------------------
-- intro :: u256 → Timestamp + ⊥
------------------------------------------------------------------------

public export
intro : U256 -> Maybe Timestamp
intro t with (inTimestamp t) proof eq
  intro t | True  = Just (t ** eqToSo eq)
  intro t | False = Nothing

------------------------------------------------------------------------
-- elim :: Timestamp → u32
------------------------------------------------------------------------

public export
elim : Timestamp -> U32
elim (t ** _) = toU32 t

------------------------------------------------------------------------
-- ago :: Timestamp × u32 → Timestamp + ⊥
------------------------------------------------------------------------

public export
ago : Timestamp -> U32 -> Maybe Timestamp
ago (t ** _) delta with (fromU32 delta <= t)
  ago (t ** _) delta | False = Nothing
  ago (t ** _) delta | True with (inTimestamp (t - fromU32 delta)) proof eq
    ago (t ** _) delta | True | False = Nothing
    ago (t ** _) delta | True | True  = Just ((t - fromU32 delta) ** eqToSo eq)

------------------------------------------------------------------------
-- (≤) :: Timestamp × Timestamp → 2
------------------------------------------------------------------------

public export
lte : Timestamp -> Timestamp -> Bool
lte (t1 ** _) (t2 ** _) = t1 <= t2
