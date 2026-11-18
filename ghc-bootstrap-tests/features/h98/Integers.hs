module Main (main) where

import Data.Bits
import Data.List (foldl')
import Numeric (showHex, showOct, readHex)

digitSum :: Integer -> Integer
digitSum 0 = 0
digitSum n = n `mod` 10 + digitSum (n `div` 10)

-- Integer square root by Newton's method
isqrt :: Integer -> Integer
isqrt 0 = 0
isqrt n = go n
  where
    go x = let y = (x + n `div` x) `div` 2 in if y >= x then x else go y

-- Operands of mixed sizes and signs, from a linear congruential generator
lcg :: Integer -> Integer
lcg x = (x * 6364136223846793005 + 1442695040888963407) `mod` (2 ^ 64)

operands :: [Integer]
operands = take 200 (map shape (iterate lcg 42))
  where
    shape x =
      let e = fromInteger (x `mod` 7) :: Int
          s = if odd (x `div` 7) then -1 else 1
       in s * (x `div` 13 + 1) ^ e

law :: Integer -> Integer -> Bool
law a b =
  let (q, r) = quotRem a b
      (d, m) = divMod a b
   in q * b + r == a && abs r < abs b && d * b + m == a && abs m < abs b
        && (r == 0 || signum r == signum a)
        && (m == 0 || signum m == signum b)

main :: IO ()
main = do
  print (product [1 .. 25 :: Integer])
  print (digitSum (2 ^ 1000), digitSum (product [1 .. 100]))
  print (2 ^ 64 :: Integer, gcd (2 ^ 100) (6 ^ 50 :: Integer), lcm 12 (18 :: Integer))
  print [(-7) `div` 2, (-7) `mod` 2, (-7) `quot` 2, (-7) `rem` 2 :: Integer]
  print (divMod (-(10 ^ 30 + 7)) (10 :: Integer), quotRem (-(10 ^ 30 + 7)) (10 :: Integer))
  print (maxBound :: Int, minBound :: Int, (maxBound :: Int) + 1 == minBound)
  print (fromIntegral (2 ^ 63 :: Integer) :: Int, toInteger (maxBound :: Int) + 1)
  print (shiftL 1 100 == (2 ^ 100 :: Integer), testBit (2 ^ 70 :: Integer) 70, (2 ^ 70 - 1 :: Integer) .&. 255)
  print (fromInteger (2 ^ 53 + 1) :: Double, fromInteger (3 ^ 40) :: Double)
  print (truncate (1.0e20 :: Double) :: Integer, round (-2.5e15 :: Double) :: Integer)
  print (read "123456789012345678901234567890" :: Integer, read "-42" :: Integer)
  putStrLn (showHex (2 ^ 80 - 1 :: Integer) "" ++ " " ++ showOct (511 :: Integer) "")
  print (fst (head (readHex "deadbeefcafebabe1234" :: [(Integer, String)])))
  let pairs = [(a, b) | a <- operands, b <- take 50 operands, b /= 0]
  print (length pairs, length (filter (not . uncurry law) pairs))
  print (length [() | n <- map abs operands, let s = isqrt n, s * s <= n, n < (s + 1) * (s + 1)])
  print (foldl' (\acc x -> (acc * 31 + x) `mod` 1000000007) 0 [q + r | (a, b) <- pairs, let (q, r) = divMod a b])
  print (sum (map (`mod` 1000003) operands), product (map ((+ 1) . (`mod` 97)) (take 40 operands)))
  print (fib 300, length (show (fib 10000)))
  where
    fib :: Int -> Integer
    fib n = fst (foldl' (\(a, b) _ -> (b, a + b)) (0, 1) [1 .. n])
