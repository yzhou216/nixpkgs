module Main (main) where

import Language.Haskell.Parser
import Language.Haskell.Pretty
import Language.Haskell.Syntax

src :: String
src = unlines
  [ "module M where"
  , "f :: Int -> Int"
  , "f x = x * 2 + 1"
  , "data T = A | B Int deriving Show"
  ]

main :: IO ()
main = case parseModule src of
  ParseOk m@(HsModule _ _ _ _ decls) -> do
    print (length decls)
    let s = prettyPrint m
    case parseModule s of
      ParseOk m2 -> putStrLn (if prettyPrint m2 == s then "round trip ok" else "round trip differs")
      ParseFailed _ e -> putStrLn ("reparse failed: " ++ e)
  ParseFailed _ e -> putStrLn ("parse failed: " ++ e)
