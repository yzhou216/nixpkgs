module Main (main) where

import Data.List (sort)
import Debug.QuickCheck

prop_reverse :: [Int] -> Bool
prop_reverse xs = reverse (reverse xs) == xs

prop_sort :: [Int] -> Bool
prop_sort xs = let s = sort xs in sort s == s && length s == length xs

prop_assoc :: Integer -> Integer -> Integer -> Bool
prop_assoc a b c = (a + b) + c == a + (b + c)

main :: IO ()
main = do
  quickCheck prop_reverse
  quickCheck prop_sort
  quickCheck prop_assoc
