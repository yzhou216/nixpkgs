module Main (main) where

-- Where GHC 6.2.2 prints otherwise than GHC 9.8.4, by its own definitions.
-- floatToDigits in 6.2.2's GHC/Float.lhs takes the lower margin of a power
-- of two as b rather than b^e, so it prints more digits than it needs (the
-- value read back is the same).  realToFrac goes through toRational, so a
-- Float 0.1 widens to its exact value; GHC 9.8.4 folds the literal instead.
main :: IO ()
main = do
  print (2 ^ 62 :: Float, read (show (2 ^ 62 :: Float)) == (2 ^ 62 :: Float))
  print (realToFrac (0.1 :: Float) :: Double)
