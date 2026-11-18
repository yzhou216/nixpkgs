module Main (main) where

import Data.Char (chr, digitToInt, intToDigit, isAlpha, isSpace, ord, toUpper)
import Data.List
import Data.Maybe (catMaybes, fromMaybe, mapMaybe)

data Colour = Red | Green | Blue deriving (Show, Read, Eq, Ord, Enum, Bounded)

data P = P {px :: Int, py :: Double} deriving (Show, Read, Eq, Ord)

data T = Leaf | Node T Int T deriving (Show, Read, Eq)

infixr 5 :+:

data E = Lit Integer | E :+: E | Neg E deriving (Show, Read, Eq)

newtype W = W {unW :: [Maybe (Int, Char)]} deriving (Show, Read, Eq)

insertT :: Int -> T -> T
insertT x Leaf = Node Leaf x Leaf
insertT x t@(Node l y r)
  | x < y = Node (insertT x l) y r
  | x > y = Node l y (insertT x r)
  | otherwise = t

toList :: T -> [Int]
toList Leaf = []
toList (Node l x r) = toList l ++ [x] ++ toList r

eval :: E -> Integer
eval (Lit n) = n
eval (a :+: b) = eval a + eval b
eval (Neg e) = negate (eval e)

rot13 :: Char -> Char
rot13 c
  | c >= 'a' && c <= 'z' = r 'a'
  | c >= 'A' && c <= 'Z' = r 'A'
  | otherwise = c
  where
    r b = chr ((ord c - ord b + 13) `mod` 26 + ord b)

main :: IO ()
main = do
  print [minBound .. maxBound :: Colour]
  print (read "[Red,Blue , Green]" :: [Colour], succ Red, fromEnum Blue, [Red ..], compare Green Blue)
  print (P 3 (-2.5), P {py = 1e-3, px = -7})
  print (read " P { px = -1 , py = 2.0e2 } " :: P)
  let e = Lit 1 :+: Neg (Lit (-2)) :+: Lit 3
  print e
  print (read (show e) == e, eval e)
  print (read "Lit 1 :+: (Neg (Lit (-2)) :+: Lit 3)" :: E)
  print (W [Just (1, 'a'), Nothing, Just (-2, '\n')])
  print (read (show (W [Just (1, '\t'), Nothing])) == W [Just (1, '\t'), Nothing])
  let t = foldr insertT Leaf [5, 3, 8, 1, 4, 7, 9, 2, 6 :: Int]
  print t
  print (toList t, read (show t) == t)
  print "esc: \"\\\1234\SOH\DEL\200\&9\SO\&H"
  print (show 'x', show '\'', show '\0', [chr 200, chr 1000])
  print (reads "12 rest" :: [(Int, String)], reads "(1,'x') z" :: [((Int, Char), String)])
  print (read "(  3 , -4 )" :: (Int, Int), read "[(1,\"a\"),(2,\"b\")]" :: [(Int, String)])
  print (read "Just (-3)" :: Maybe Int, read "Left 2" :: Either Int Bool, read "  ( ( 5 ) ) " :: Int)
  print (words "  the quick\tbrown\n fox  ", unwords ["a", "b"], lines "x\ny\n\nz", unlines ["p", "q"])
  print (map toUpper "hello", map rot13 "Hello, World!", filter isAlpha "a1b2c3", map digitToInt "fF09", map intToDigit [0, 9, 10, 15])
  print (sort "mississippi", group (sort "mississippi"), nub [3, 1, 3, 2, 1 :: Int])
  print (sortBy (\a b -> compare (snd a) (snd b)) (zip [1 :: Int ..] "banana"))
  print (groupBy (\a b -> even a == even b) [2, 4, 1, 3, 6, 8, 5 :: Int], partition even [1 .. 10 :: Int])
  print (transpose ["abc", "de", "f"], intersperse ',' "abc", isPrefixOf "ab" "abc", isSuffixOf "bc" "abc")
  print (unfoldr (\n -> if n > 100 then Nothing else Just (n, n * 2)) (1 :: Int), insert 4 [1, 3, 5, 7 :: Int], delete 'a' "banana")
  print ([1, 2, 3, 4] \\ [2, 4 :: Int], union [1, 2] [2, 3 :: Int], intersect [1, 2, 3] [2, 3, 4 :: Int], tails "abc", inits "abc")
  print (mapMaybe (\x -> if x > 2 then Just (x * x) else Nothing) [1 .. 5 :: Int], catMaybes [Just 'a', Nothing, Just 'b'], fromMaybe 0 (lookup 'z' (zip "abc" [1 :: Int ..])))
  print (zipWith3 (\a b c -> a + b * c) [1, 2] [3, 4] [5, 6 :: Int], unzip3 [(1 :: Int, 'a', True), (2, 'b', False)])
  print (take 10 (cycle [1, 2, 3 :: Int]), replicate 3 'x', splitAt 2 "hello", span isSpace "  x ", break (== ' ') "ab cd")
  print ([1.0, 1.5 .. 3.0 :: Double], [10, 8 .. 1 :: Int], ['a' .. 'e'], [LT ..], take 3 [False ..])
  print (showsPrec 11 (-5 :: Int) "", show (Just (Left (3, 'c') :: Either (Int, Char) ())), show [Just [Nothing, Just True]])
  print (foldl' (flip (:)) [] "abc", scanl (+) 0 [1, 2, 3 :: Int], scanr1 max [3, 1, 4, 1, 5 :: Int], iterate (* 2) 1 !! 20 :: Int)
  print (lookup 2 [(1, "one"), (2, "two")], elem 3 [1, 2, 3 :: Int], maximumBy (\a b -> compare (length a) (length b)) ["a", "abc", "ab"], genericLength "abcd" :: Integer)
