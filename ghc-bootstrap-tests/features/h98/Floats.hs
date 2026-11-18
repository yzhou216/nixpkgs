module Main (main) where

import Data.Ratio
import Data.List (foldl')
import Numeric (floatToDigits, showEFloat, showFFloat, showGFloat)

main :: IO ()
main = do
  print [0.1, 0.1 + 0.2, 1 / 3, 1.0e22, 5.0e-324, 1.0e-310, 123456.789 :: Double]
  print [pi, sqrt 2, exp 1, log 10, sin 1, atan2 1 (-1), 2 ** 0.5 :: Double]
  print [pi, sqrt 2, 0.1 :: Float]
  print (1 / 0 :: Double, -1 / 0 :: Double, isNaN (0 / 0 :: Double), isNegativeZero (-0.0 :: Double))
  print (map round [2.5, 3.5, -2.5, -3.5, 0.5 :: Double] :: [Integer])
  print (map truncate [2.7, -2.7 :: Double] :: [Int], map floor [2.5, -2.5 :: Double] :: [Int], map ceiling [2.1, -2.1 :: Double] :: [Int])
  print (properFraction (-3.75 :: Double) :: (Integer, Double))
  print (decodeFloat (1.0 :: Double), decodeFloat (0.1 :: Float), significand (8 :: Double), exponent (8 :: Double))
  print (encodeFloat 1 1024 :: Double, encodeFloat 3 (-1074) :: Double, isDenormalized (5.0e-324 :: Double))
  print (floatDigits (1 :: Double), floatRange (1 :: Double), floatDigits (1 :: Float), floatRadix (1 :: Float))
  putStrLn (unwords [showFFloat (Just 3) (3.14159 :: Double) "", showEFloat (Just 2) (1234.5 :: Double) "", showGFloat (Just 2) (0.05 :: Double) "", showFFloat Nothing (1.0e-4 :: Double) ""])
  print (floatToDigits 10 (0.3 :: Double), floatToDigits 2 (0.75 :: Double))
  print (toRational (0.75 :: Double), fromRational (1 % 3) :: Double, realToFrac (read "0.1" :: Float) :: Double)
  print (read "1e-310" :: Double, read "  -2.5e3 " :: Double, read "3" :: Double)
  print (truncate (1.0e10 :: Double) :: Int, fromIntegral (maxBound :: Int) :: Double, fromIntegral (2 ^ 62 + 2 ^ 41 :: Int) :: Float)
  print (foldl' (+) 0 [1 / fromIntegral n | n <- [1 .. 100000 :: Int]] :: Double)
  print (foldr (\x acc -> x + acc / 2) 0 (map fromIntegral [1 .. 60 :: Int]) :: Double)
  print (maximum [1 / 0, 5 :: Double], minimum [3.5, -1.25, 2 :: Double])
  print [x * x - 2 | x <- take 6 (iterate (\x -> (x + 2 / x) / 2) (1 :: Double))]
  print (1 % 3 + 1 % 6 :: Rational, numerator (6 % 8 :: Rational), (-1) % 2 :: Rational)
