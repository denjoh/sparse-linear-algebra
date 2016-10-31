-----------------------------------------------------------------------------
-- |
-- Copyright   :  (C) 2016 Marco Zocca, 2012-2015 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  portable
--
-- Testing for values "near" zero
-----------------------------------------------------------------------------
module Numeric.Eps
  ( Epsilon(..), nearZero, isNz, roundZero, roundOne, roundZeroOne
  ) where
import Foreign.C.Types (CFloat, CDouble)

-- | Provides a test to see if a quantity is near zero.
--
-- >>> nearZero (1e-11 :: Double)
-- False
--
-- >>> nearZero (1e-17 :: Double)
-- True
--
-- >>> nearZero (1e-5 :: Float)
-- False
--
-- >>> nearZero (1e-7 :: Float)
-- True
class Num a => Epsilon a where
  -- | Determine if a quantity is near zero.
  nearZero :: a -> Bool

-- | @'abs' a '<=' 1e-6@
instance Epsilon Float where
  nearZero a = abs a <= 1e-6

-- | @'abs' a '<=' 1e-12@
instance Epsilon Double where
  nearZero a = abs a <= 1e-12

-- | @'abs' a '<=' 1e-6@
instance Epsilon CFloat where
  nearZero a = abs a <= 1e-6

-- | @'abs' a '<=' 1e-12@
instance Epsilon CDouble where
  nearZero a = abs a <= 1e-12




-- * Rounding operations


-- | Rounding rule
almostZero, almostOne, isNz :: Epsilon a => a -> Bool
almostZero x = nearZero x -- abs (toRational x) <= eps
almostOne x = nearZero (1 - x)-- x' >= (1-eps) && x' < (1+eps) where x' = toRational x
isNz x = not (almostZero x)

withDefault :: (t -> Bool) -> t -> t -> t
withDefault q d x | q x = d
                  | otherwise = x

roundZero, roundOne, roundZeroOne :: Epsilon a => a -> a
roundZero = withDefault almostZero (fromIntegral 0)
roundOne = withDefault almostOne (fromIntegral 1)

with2Defaults :: (t -> Bool) -> (t -> Bool) -> t -> t -> t -> t
with2Defaults q1 q2 d1 d2 x | q1 x = d1
                            | q2 x = d2
                            | otherwise = x

-- | Round to respectively 0 or 1
roundZeroOne = with2Defaults almostZero almostOne (fromIntegral 0) (fromIntegral 1)
