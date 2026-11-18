{-# OPTIONS -fglasgow-exts #-}
module Main (main) where

import Control.Monad.State
import Data.Generics
import GHC.Exts

-- Rank-2 argument
applyBoth :: (forall a. [a] -> [a]) -> ([Int], String) -> ([Int], String)
applyBoth f (xs, s) = (f xs, f s)

-- Existential type
data Showable = forall a. Show a => MkShowable a

instance Show Showable where
  show (MkShowable a) = show a

-- Multi-parameter class with a functional dependency
class Collection c e | c -> e where
  cinsert :: e -> c -> c
  cempty :: c
  ctoList :: c -> [e]

newtype IntBag = IntBag [Int]

instance Collection IntBag Int where
  cinsert x (IntBag xs) = IntBag (x : xs)
  cempty = IntBag []
  ctoList (IntBag xs) = reverse xs

-- Implicit parameter
greet :: (?name :: String) => String
greet = "hello " ++ ?name

-- Unboxed arithmetic
sumTo :: Int# -> Int# -> Int#
sumTo 0# acc = acc
sumTo n acc = sumTo (n -# 1#) (acc +# n)

-- Pattern guards
classify :: [(String, Int)] -> String -> String
classify env k
  | Just v <- lookup k env, v > 0 = "positive"
  | Just _ <- lookup k env = "non-positive"
  | otherwise = "missing"

-- Generic traversal over a derived Data instance
data Expr = Num Int | Add Expr Expr | Mul Expr Expr deriving (Show, Typeable, Data)

simplify :: Expr -> Expr
simplify = everywhere (mkT step)
  where
    step (Mul (Num 1) e) = e
    step (Add e (Num 0)) = e
    step e = e

-- Nodes in a value, Int leaves included
gcount :: GenericQ Int
gcount t = 1 + sum (gmapQ gcount t)

isBig :: Expr -> Bool
isBig (Num n) = n > 1
isBig _ = False

-- State monad from base
labels :: State Int [Int]
labels = mapM (\x -> do n <- get; put (n + x); return n) [1 .. 5]

-- Strict, unpacked fields
data V = V {-# UNPACK #-} !Double {-# UNPACK #-} !Double

norm2 :: V -> Double
norm2 (V x y) = x * x + y * y

-- A rewrite rule that changes the result, so that it shows whether it fired
mymap :: (a -> b) -> [a] -> [b]
mymap = map
{-# NOINLINE mymap #-}
{-# RULES "mymap/twice" forall f g xs. mymap f (mymap g xs) = mymap (\x -> f (g x) + 1000) xs #-}

class Pretty a where
  pretty :: a -> String
  pretty _ = "<default>"

instance Pretty Bool where
  pretty b = if b then "yes" else "no"

instance Pretty () -- uses the default method

main :: IO ()
main = do
  print (applyBoth reverse ([1, 2, 3], "abc"))
  print [MkShowable (1 :: Int), MkShowable "two", MkShowable (Just 'c')]
  print (ctoList (cinsert 3 (cinsert 2 (cinsert 1 (cempty :: IntBag)))))
  let ?name = "world" in putStrLn greet
  print (I# (sumTo 100# 0#))
  print (map (classify [("a", 1), ("b", 0)]) ["a", "b", "c"])
  print (simplify (Add (Mul (Num 1) (Num 5)) (Add (Num 2) (Num 0))))
  print (typeOf (Just 'x'), typeOf [1 :: Int], typeOf (undefined :: Int -> Bool))
  print (gcount (Add (Num 1) (Num 2)), listify isBig (Add (Num 1) (Mul (Num 2) (Num 3))))
  print (runState labels 10)
  print (norm2 (V 3 4))
  print (mymap (* 2) (mymap (+ 1) [1, 2, 3 :: Int]))
  putStrLn (pretty True ++ " " ++ pretty ())
  print (W# (int2Word# 3#), C# (chr# 65#), D# (2.5## *## 2.0##))
