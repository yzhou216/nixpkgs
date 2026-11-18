module Main (main) where

import Data.List (sort)
import Debug.QuickCheck

prop_reverse :: [Int] -> Bool
prop_reverse xs = reverse (reverse xs) == xs

prop_sort :: [Int] -> Bool
prop_sort xs = let s = sort xs in sort s == s && length s == length xs

prop_assoc :: Integer -> Integer -> Integer -> Bool
prop_assoc a b c = (a + b) + c == a + (b + c)

-- quickCheck's settings without the progress counter
quiet :: Config
quiet = Config {configMaxTest = 100, configMaxFail = 1000, configSize = (+ 3) . (`div` 2), configEvery = \_ _ -> ""}

main :: IO ()
main = do
  check quiet prop_reverse
  check quiet prop_sort
  check quiet prop_assoc
