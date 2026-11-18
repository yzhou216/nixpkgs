module Main (main) where

import Control.Concurrent.MVar
import Control.Exception
import System.Exit

-- Blocked on an MVar that no other thread can fill.  The result is the exit
-- status: detecting the deadlock also finalizes stdout in GHC 6.2.2.
main :: IO ()
main = do
  r <- try (newEmptyMVar >>= \m -> takeMVar (m :: MVar ()))
  case r of
    Left BlockedOnDeadMVar -> exitWith (ExitFailure 3)
    Left _ -> exitWith (ExitFailure 4)
    Right () -> exitWith (ExitFailure 5)
