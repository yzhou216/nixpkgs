module Main (main) where

import Text.ParserCombinators.Parsec
import Text.ParserCombinators.Parsec.Expr

expr :: Parser Integer
expr = buildExpressionParser table factor
  where
    table =
      [ [op "*" (*) AssocLeft, op "/" div AssocLeft]
      , [op "+" (+) AssocLeft, op "-" (-) AssocLeft]
      ]
    op s f = Infix (string s >> spaces >> return f)

factor :: Parser Integer
factor = (char '(' >> spaces >> expr >>= \e -> char ')' >> spaces >> return e) <|> number

number :: Parser Integer
number = many1 digit >>= \ds -> spaces >> return (read ds)

main :: IO ()
main = do
  print (parse (spaces >> expr) "" "1 + 2 * 3 - (4 / 2)")
  putStrLn (either (const "parse error") show (parse (expr >> eof) "" "1 + * 2"))
  print (parse (sepBy (many1 letter) (char ',')) "" "ab,cd,ef")
