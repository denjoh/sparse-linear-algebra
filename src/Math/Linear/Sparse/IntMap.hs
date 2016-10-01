module Math.Linear.Sparse.IntMap where

import qualified Data.IntMap.Strict as IM




-- | ========= IntMap-of-IntMap (IM2) stuff


-- insert an element
insertIM2 ::
  IM.Key -> IM.Key -> a -> IM.IntMap (IM.IntMap a) -> IM.IntMap (IM.IntMap a)
insertIM2 i j x imm = IM.insert i (IM.insert j x ro) imm where
  ro = maybe (IM.singleton j x) (IM.insert j x) (IM.lookup i imm)

-- lookup a key
lookupIM2 ::
  IM.Key -> IM.Key -> IM.IntMap (IM.IntMap a) -> Maybe a
lookupIM2 i j imm = IM.lookup i imm >>= IM.lookup j

-- populate an IM2 from a list of (row index, column index, value)  
fromListIM2 ::
  Foldable t =>
     t (IM.Key, IM.Key, a) -> IM.IntMap (IM.IntMap a) -> IM.IntMap (IM.IntMap a)
fromListIM2 iix sm = foldl ins sm iix where
  ins t (i,j,x) = insertIM2 i j x t

-- indexed fold over an IM2
ifoldlIM2 ::
  (IM.Key -> IM.Key -> t -> IM.IntMap a -> IM.IntMap a) ->
  IM.IntMap (IM.IntMap t) ->  
  IM.IntMap a
ifoldlIM2 f m         = IM.foldlWithKey' accRow IM.empty m where
  accRow    acc i row = IM.foldlWithKey' (accElem i) acc row
  accElem i acc j x   = f i j x acc

-- transposeIM2 : inner indices become outer ones and vice versa. No loss of information because both inner and outer IntMaps are nubbed.
transposeIM2 :: IM.IntMap (IM.IntMap a) -> IM.IntMap (IM.IntMap a)
transposeIM2 = ifoldlIM2 (flip insertIM2)


-- map over outer IM and filter all inner IM's
ifilterIM2 ::
  (IM.Key -> IM.Key -> a -> Bool) ->
  IM.IntMap (IM.IntMap a) ->
  IM.IntMap (IM.IntMap a)
ifilterIM2 f  =
  IM.mapWithKey (\irow row -> IM.filterWithKey (f irow) row) 


-- map over IM2

mapIM2 :: (a -> b) -> IM.IntMap (IM.IntMap a) -> IM.IntMap (IM.IntMap b)
mapIM2 = IM.map . IM.map   -- imapIM2 (\_ _ x -> f x)


-- indexed map over IM2
imapIM2 ::
  (IM.Key -> IM.Key -> a -> b) ->
  IM.IntMap (IM.IntMap a) ->
  IM.IntMap (IM.IntMap b)
imapIM2 f im = IM.mapWithKey ff im where
  ff j x = IM.mapWithKey (`f` j) x




-- map over a single `column`

mapColumnIM2 :: (b -> b) -> IM.IntMap (IM.IntMap b) -> Int -> IM.IntMap (IM.IntMap b)
mapColumnIM2 f im jj = imapIM2 (\i j x -> if j == jj then f x else x) im