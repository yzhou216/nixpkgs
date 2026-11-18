{-# OPTIONS -fglasgow-exts #-}
module Main (main) where

import Prelude hiding (catch)
import Control.Exception
import Data.Array
import Data.Dynamic
import Data.IORef
import System.Exit
import System.IO hiding (catch, try)
import System.IO.Error (ioeGetFileName, isDoesNotExistError)

data MyErr = MyErr Int deriving (Show, Typeable)

data R = A {fieldA :: Int} | B {fieldB :: Int}

classify :: Exception -> String
classify (ErrorCall s) = "ErrorCall " ++ s
classify (ArithException e) = "ArithException " ++ show e
classify (IOException _) = "IOException"
classify (ExitException c) = "ExitException " ++ show c
classify (AsyncException e) = "AsyncException " ++ show e
classify (PatternMatchFail _) = "PatternMatchFail"
classify (RecSelError _) = "RecSelError"
classify (DynException d) = case fromDynamic d of
  Just (MyErr n) -> "MyErr " ++ show n
  Nothing -> "DynException"
classify e = "other: " ++ show e

probe :: String -> IO a -> IO ()
probe name act = do
  r <- try act
  putStrLn (name ++ ": " ++ either classify (const "no exception") r)

main :: IO ()
main = do
  probe "error" (evaluate (error "boom" :: Int))
  probe "div" (evaluate (1 `div` (0 :: Int)))
  probe "head" (evaluate (head ([] :: [Int])))
  probe "pattern" (evaluate ((\(Just x) -> x) (Nothing :: Maybe Int)))
  probe "recsel" (evaluate (fieldB (A 1)))
  probe "ioError" (ioError (userError "custom"))
  probe "openFile" (openFile "/nonexistent/file" ReadMode)
  probe "exit" (exitWith (ExitFailure 3))
  probe "dyn" (throwDyn (MyErr 42) :: IO ())
  probe "array" (evaluate (listArray (0, 2) [1, 2, 3 :: Int] ! 5))
  probe "stack" (evaluate (foldr (+) 0 [1 .. 10000000 :: Int]))

  -- Order of bracket and finally actions
  logRef <- newIORef []
  let say s = modifyIORef logRef (s :)
  try (bracket (say "acquire" >> return (5 :: Int)) (\_ -> say "release") (\x -> say ("use " ++ show x) >> throwIO (ErrorCall "inside")))
  say "body" `finally` say "finally"
  readIORef logRef >>= print . reverse

  r <- try (openFile "/nonexistent/file" ReadMode)
  case r of
    Left (IOException e) -> print (isDoesNotExistError e, ioeGetFileName e)
    _ -> putStrLn "unexpected"
  catchJust errorCalls (evaluate (error "picked" :: Int) >> return "none") return >>= putStrLn
  r3 <- try (catch (throwIO (ErrorCall "first")) (\_ -> throwIO (ErrorCall "second")))
  putStrLn (either classify (const "none") (r3 :: Either Exception ()))
  block (unblock (return ())) >> putStrLn "block ok"
