{-# language ScopedTypeVariables #-}
module LibSpec where

import Numeric.LinearAlgebra.Sparse
-- import Numeric.LinearAlgebra.Class

import Data.Sparse.Common


import qualified Data.IntMap as IM

import Control.Monad (replicateM)
import Control.Monad.State.Strict (execState)

import qualified System.Random.MWC as MWC
import qualified System.Random.MWC.Distributions as MWC
       
import Test.Hspec
-- import Test.Hspec.QuickCheck




main :: IO ()
main = hspec spec

-- niter = 5

spec :: Spec
spec = do
  describe "Math.Linear.Sparse : library" $ do
    -- prop "subtraction is cancellative" $ \(x :: SpVector Double) ->
    --   x ^-^ x `shouldBe` zero
    it "dot : inner product" $
      tv0 `dot` tv0 `shouldBe` 61
    it "transposeSM : sparse matrix transpose" $
      transposeSM m1 `shouldBe` m1t
    it "matVec : matrix-vector product" $
      normSq ((aa0 #> x0true) ^-^ b0 ) <= eps `shouldBe` True
    it "vecMat : vector-matrix product" $
      normSq ((x0true <# aa0) ^-^ aa0tx0 ) <= eps `shouldBe` True  
    it "matMat : matrix-matrix product" $
      (m1 `matMat` m2) `shouldBe` m1m2
    it "eye : identity matrix" $
      infoSM (eye 10) `shouldBe` SMInfo 10 0.1
    it "countSubdiagonalNZ : # of nonzero elements below the diagonal" $
      countSubdiagonalNZSM m3 `shouldBe` 1
    it "modifyInspectN : early termination by iteration count" $
      execState (modifyInspectN 2 ((< eps) . diffSqL) (/2)) 1 `shouldBe` 1/8
    it "modifyInspectN : termination by value convergence" $
      execState (modifyInspectN (2^16) ((< eps) . head) (/2)) 1 < eps `shouldBe` True 
  describe "Math.Linear.Sparse : Linear solvers" $ do
    it "BCG (2 x 2 dense)" $
      normSq (_xBcg (bcg aa0 b0 x0) ^-^ x0true) <= eps `shouldBe` True
    it "BiCGSTAB (2 x 2 dense)" $ 
      normSq (aa0 <\> b0 ^-^ x0true) <= eps `shouldBe` True
    it "CGS (2 x 2 dense)" $ 
      normSq (_x (cgs aa0 b0 x0 x0) ^-^ x0true) <= eps `shouldBe` True
  describe "Math.Linear.Sparse : QR decomposition" $ do    
    it "QR (4 x 4 sparse)" $
      checkQr tm4 `shouldBe` True
    it "QR (3 x 3 dense)" $ 
      checkQr tm2 `shouldBe` True
    
  -- let n = 10
  --     nsp = 3
  -- describe ("random sparse linear system of size " ++ show n ++ " and sparsity " ++ show (fromIntegral nsp/fromIntegral n)) $ it "<\\>" $ do
  --   aa <- randSpMat n nsp
  --   xtrue <- randSpVec n nsp
  --   b <- randSpVec n nsp    
  --   let b = aa #> xtrue
  --   printDenseSM aa
  --   normSq (aa <\> b ^-^ xtrue) <= eps `shouldBe` True
  -- --     normSq (_xBicgstab (bicgstab aa b x0 x0) ^-^ x) <= eps `shouldBe` True



-- -- run N iterations 

-- runNBiC :: Int -> SpMatrix Double -> SpVector Double -> BICGSTAB
runNBiC n aa b = map _xBicgstab $ runAppendN' (bicgstabStep aa x0) n bicgsInit where
   x0 = mkSpVectorD nd $ replicate nd 0.9
   nd = dim r0
   r0 = b ^-^ (aa #> x0)    
   p0 = r0
   bicgsInit = BICGSTAB x0 r0 p0

-- runNCGS :: Int -> SpMatrix Double -> SpVector Double -> CGS
runNCGS n aa b = map _x $ runAppendN' (cgsStep aa x0) n cgsInit where
  x0 = mkSpVectorD nd $ replicate nd 0.1
  nd = dim r0
  r0 = b ^-^ (aa #> x0)    -- residual of initial guess solution
  p0 = r0
  u0 = r0
  cgsInit = CGS x0 r0 p0 u0  


{-

example 0 : 2x2 linear system

[1 2] [2] = [8]
[3 4] [3]   [18]


[1 3] [2] = [11]
[2 4] [3]   [16]


-}

aa0 :: SpMatrix Double
aa0 = SM (2,2) im where
  im = IM.fromList [(0, aa0r0), (1, aa0r1)]

aa0r0, aa0r1 :: IM.IntMap Double
aa0r0 = IM.fromList [(0,1),(1,2)]
aa0r1 = IM.fromList [(0,3),(1,4)]


-- b0, x0 : r.h.s and initial solution resp.
b0, x0, x0true :: SpVector Double
b0 = mkSpVectorD 2 [8,18]
x0 = mkSpVectorD 2 [0.3,1.4]


-- x0true : true solution
x0true = mkSpVectorD 2 [2,3]



aa0tx0 = mkSpVectorD 2 [11,16]







{- 4x4 system -}

aa1 :: SpMatrix Double
aa1 = sparsifySM $ fromListDenseSM 4 [1,0,0,0,2,5,0,10,3,6,8,11,4,7,9,12]

x1, b1 :: SpVector Double
x1 = mkSpVectorD 4 [1,2,3,4]

b1 = mkSpVectorD 4 [30,56,60,101]



{- 3x3 system -}
aa2 :: SpMatrix Double
aa2 = sparsifySM $ fromListDenseSM 3 [2, -1, 0, -1, 2, -1, 0, -1, 2]
x2, b2 :: SpVector Double
x2 = mkSpVectorD 3 [3,2,3]

b2 = mkSpVectorD 3 [4,-2,4]



-- --

{-
example 1 : random linear system

-}



-- dense
solveRandom n = do
  aa0 <- randMat n
  let aa = aa0 ^+^ eye n
  xtrue <- randVec n
  -- x0 <- randVec n
  let b = aa #> xtrue
      dx = aa <\> b ^-^ xtrue
  return $ normSq dx
  -- let xhatB = _xBicgstab (bicgstab aa b x0 x0)
  --     xhatC = _x (cgs aa b x0 x0)
  -- return (aa, x, x0, b, xhatB, xhatC)

-- sparse
solveSpRandom :: Int -> Int -> IO Double
solveSpRandom n nsp = do
  aa0 <- randSpMat n nsp
  let aa = aa0 ^+^ eye n
  xtrue <- randSpVec n nsp
  let b = (aa ^+^ eye n) #> xtrue
      dx = aa <\> b ^-^ xtrue
  return $ normSq dx



-- `ndim` iterations

solveRandomN ndim nsp niter = do
  aa0 <- randSpMat ndim (nsp ^ 2)
  let aa = aa0 ^+^ eye ndim
  xtrue <- randSpVec ndim nsp
  let b = aa #> xtrue
      xhatB = head $ runNBiC niter aa b
      xhatC = head $ runNCGS niter aa b
  printDenseSM aa    
  return (normSq (xhatB ^-^ xtrue), normSq (xhatC ^-^ xtrue))

--

{-
matMat

[1, 2] [5, 6] = [19, 22]
[3, 4] [7, 8]   [43, 50]
-}

m1 = fromListDenseSM 2 [1,3,2,4]
m2 = fromListDenseSM 2 [5, 7, 6, 8]     
m1m2 = fromListDenseSM 2 [19, 43, 22, 50]

-- transposeSM

m1t = fromListDenseSM 2 [1,2,3,4]


--

{-
countSubdiagonalNZ
-}

m3 = fromListSM (3,3) [(0,2,3),(2,0,4),(1,1,3)] 




{- mkSubDiagonal -}

testLaplacian1 :: Int -> SpMatrix Double
testLaplacian1 n = m where
  m :: SpMatrix Double
  m = mksd (-1) l1 ^+^
       mksd 0 l2 ^+^
       mksd 1 l3
    where
    mksd = mkSubDiagonal n
    l1 = replicate n (-1)
    l2 = replicate n 2
    l3 = l1
  -- x :: SpVector Double
  -- x = mkSpVectorD n (replicate n 2)
  -- b = m #> x

-- t3 n = normSq $ (aa <\> b) ^-^ xhat where
--   aa = testLaplacian1 n :: SpMatrix Double
--   xhat = mkSpVectorD n (concat $ replicate 20 [1,2,3,4,5]) :: SpVector Double
--   b = aa #> xhat

{- QR-}

checkQr :: SpMatrix Double -> Bool
checkQr a = c1 && c2 where
  (q, r) = qr a
  c1 = normFrobenius ((q #~# r) ^-^ a) <= eps
  c2 = isOrthogonalSM q


aa22 = fromListDenseSM 2 [2,1,1,2] :: SpMatrix Double




{- eigenvalues -}


aa3 = fromListDenseSM 3 [1,1,3,2,2,2,3,1,1] :: SpMatrix Double

b3 = mkSpVectorD 3 [1,1,1] :: SpVector Double



-- aa4 : eigenvalues 1 (mult.=2) and -1
aa4 = fromListDenseSM 3 [3,2,-2,2,2,-1,6,5,-4] :: SpMatrix Double

b4 = fromListDenseSV 3 [-3,-3,-3] :: SpVector Double








-- test data

tm0, tm1, tm2, tm3, tm4 :: SpMatrix Double
tm0 = fromListSM (2,2) [(0,0,pi), (1,0,sqrt 2), (0,1, exp 1), (1,1,sqrt 5)]

tv0, tv1 :: SpVector Double
tv0 = mkSpVectorD 2 [5, 6]


tv1 = SV 2 $ IM.singleton 0 1

-- wikipedia test matrix for Givens rotation

tm1 = sparsifySM $ fromListDenseSM 3 [6,5,0,5,1,4,0,4,3]

tm1g1 = givens tm1 1 0
tm1a2 = tm1g1 ## tm1

tm1g2 = givens tm1a2 2 1
tm1a3 = tm1g2 ## tm1a2

tm1q = transposeSM (tm1g2 ## tm1g1)


-- wp test matrix for QR decomposition via Givens rotation

tm2 = fromListDenseSM 3 [12, 6, -4, -51, 167, 24, 4, -68, -41]




tm3 = transposeSM $ fromListDenseSM 3 [1 .. 9]

tm3g1 = fromListDenseSM 3 [1, 0,0, 0,c,-s, 0, s, c]
  where c= 0.4961
        s = 0.8682


--

tm4 = sparsifySM $ fromListDenseSM 4 [1,0,0,0,2,5,0,10,3,6,8,11,4,7,9,12]
