module Main (main) where

import Control.Monad
import Control.Monad.ST
import Data.Array.ST
import Data.Array.Unboxed
import Data.IORef
import Data.List (foldl', sort)
import Data.STRef

sieve :: Int -> UArray Int Bool
sieve n = runST (do
  a <- newArray (2, n) True :: ST s (STUArray s Int Bool)
  mapM_ (\i -> do
    p <- readArray a i
    when (p && i * i <= n) (mapM_ (\j -> writeArray a j False) [i * i, i * i + i .. n])) [2 .. n]
  freeze a)

queens :: Int -> Int
queens n = length (go n)
  where
    go 0 = [[]]
    go k = [q : qs | qs <- go (k - 1), q <- [1 .. n], safe q qs]
    safe q qs = and [q /= c && abs (q - c) /= d | (d, c) <- zip [1 ..] qs]

collatz :: Int -> Int
collatz = go 1
  where
    go acc 1 = acc
    go acc m = go (acc + 1) (if even m then m `div` 2 else 3 * m + 1)

matMul :: Array (Int, Int) Integer -> Array (Int, Int) Integer -> Array (Int, Int) Integer
matMul a b =
  array ((1, 1), (n, n)) [((i, j), sum [a ! (i, k) * b ! (k, j) | k <- [1 .. n]]) | i <- [1 .. n], j <- [1 .. n]]
  where
    (_, (n, _)) = bounds a

sumST :: [Int] -> Int
sumST xs = runST (do
  r <- newSTRef 0
  mapM_ (\x -> readSTRef r >>= \v -> v `seq` writeSTRef r (v + x)) xs
  readSTRef r)

pseudo :: [Int]
pseudo = go 7
  where
    go x = let y = (x * 1103515245 + 12345) `mod` 2147483648 in y `seq` (y : go y)

main :: IO ()
main = do
  let a = listArray (0, 4) "hello" :: Array Int Char
  print (a, bounds a, a ! 1, elems (a // [(0, 'j')]))
  print (accumArray (+) 0 (0, 4) [(x `mod` 5, 1) | x <- [1 .. 23 :: Int]] :: Array Int Int)
  print (ixmap (0, 4) (4 -) a, indices (listArray ((0, 0), (1, 2)) [1 .. 6 :: Int]))
  print (range ((0, 0), (2, 1)), index (10, 20) (15 :: Int), inRange ('a', 'z') 'q', rangeSize ((1, 1), (3, 4 :: Int)))
  let fibm = listArray ((1, 1), (2, 2)) [1, 1, 1, 0]
  print ((iterate (matMul fibm) fibm !! 99) ! (1, 2))
  let s = sieve 100000
  print (length (filter (s !) [2 .. 100000]), sum [i | i <- [2 .. 100000], s ! i])
  print (map queens [4 .. 9])
  print (foldl' max (0, 0) [(collatz i, i) | i <- [1 .. 100000]])
  print (sumST [1 .. 100000])
  r <- newIORef (0 :: Int)
  mapM_ (\x -> modifyIORef r (+ x)) [1 .. 1000]
  readIORef r >>= print
  let xs = take 100000 pseudo
  print (foldl' (\h x -> (h * 33 + x) `mod` 1000000007) 5381 (sort xs))
  print (take 5 (sort xs), sum (take 1000 xs))
  print (foldM (\acc x -> if x > 0 then Just (acc + x) else Nothing) 0 [1, 2, 3 :: Int], foldM (\acc x -> [acc + x, acc * x]) 1 [2, 3 :: Int])
  print (replicateM 2 "ab", zipWithM (\x y -> if y /= 0 then Just (x `div` y) else Nothing) [6, 8] [3, 2 :: Int], msum [Nothing, Just 'x', Just 'y'])
  print (do { x <- [1 .. 20 :: Int]; y <- [x .. 20]; z <- [y .. 20]; guard (x * x + y * y == z * z); return (x, y, z) })
  print (liftM2 (+) (Just 3) (Just (4 :: Int)), sequence [Just 1, Just 2 :: Maybe Int], mapM (\x -> [x, -x]) [1, 2 :: Int])
  let lazyFibs = 0 : 1 : zipWith (+) lazyFibs (tail lazyFibs) :: [Integer]
      primes = sieveL [2 ..] where sieveL (p : ps) = p : sieveL [x | x <- ps, x `mod` p /= 0]
  print (lazyFibs !! 200, take 15 (primes :: [Int]), takeWhile (< 60) (map (^ 2) [1 :: Int ..]))
  let ones = 1 : ones :: [Int]
      knot = let (evens, odds) = (0 : map (+ 1) odds, map (+ 1) evens) in take 5 (evens :: [Int])
  print (take 3 ones, knot, fst (1 :: Int, undefined :: Int), length [undefined, undefined :: Int])
