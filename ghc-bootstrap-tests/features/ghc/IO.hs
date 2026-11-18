module Main (main) where

import Prelude hiding (catch)
import Control.Exception
import Control.Monad (when)
import Data.Char (chr, ord, toUpper)
import qualified Data.HashTable as H
import Data.List (foldl', sort)
import System.CPUTime (getCPUTime)
import System.Cmd (system)
import System.Directory
import System.Environment (getArgs, getProgName)
import System.Exit
import System.IO
import System.IO.Error (isEOFError)
import System.Info (arch, os)
import System.Mem (performGC)
import System.Random
import System.Time

readLines :: Handle -> IO [String]
readLines h = do
  r <- try (hGetLine h)
  case r of
    Left (IOException e) | isEOFError e -> return []
    Left e -> throwIO e
    Right l -> fmap (l :) (readLines h)

main :: IO ()
main = do
  args <- getArgs
  name <- getProgName
  print (args, name)
  print (os, arch)

  -- stdin, read lazily
  input <- getContents
  print (length (lines input), map toUpper (head (lines input)))

  writeFile "a.txt" "line one\nline two\n"
  appendFile "a.txt" "line three\n"
  readFile "a.txt" >>= putStr
  h <- openFile "a.txt" ReadMode
  readLines h >>= print
  hClose h

  -- All 256 byte values through a handle and back
  hb <- openFile "bytes.bin" WriteMode
  mapM_ (hPutChar hb . chr) [0 .. 255]
  hClose hb
  hr <- openFile "bytes.bin" ReadMode
  size <- hFileSize hr
  hSeek hr AbsoluteSeek 250
  c <- hGetChar hr
  pos <- hTell hr
  eof <- hIsEOF hr
  hClose hr
  bytes <- readFile "bytes.bin"
  print (size, ord c, pos, eof, map ord bytes == [0 .. 255])

  -- A large file
  writeFile "big.txt" (unlines (map show [1 .. 200000 :: Int]))
  big <- readFile "big.txt"
  print (length big, foldl' (+) 0 (map read (lines big)) :: Integer)

  createDirectory "d"
  writeFile "d/x" "x"
  renameFile "d/x" "d/y"
  getDirectoryContents "d" >>= print . sort
  e1 <- doesFileExist "d/y"
  e2 <- doesDirectoryExist "d"
  removeFile "d/y"
  removeDirectory "d"
  e3 <- doesDirectoryExist "d"
  print (e1, e2, e3)

  r <- system "exit 7"
  r0 <- system "true"
  print (r, r0)

  ht <- H.new (==) H.hashString
  mapM_ (\i -> H.insert ht (show i) i) [1 .. 1000 :: Int]
  v1 <- H.lookup ht "500"
  v2 <- H.lookup ht "1001"
  H.delete ht "500"
  v3 <- H.lookup ht "500"
  print (v1, v2, v3)

  let g = mkStdGen 2026
      rolls = take 1000 (randomRs (1, 6) g) :: [Int]
  print (all (\x -> x >= 1 && x <= 6) rolls, length (filter (== 6) rolls) > 100)

  TOD s _ <- getClockTime
  ct <- toCalendarTime (TOD s 0)
  print (s > 1700000000, ctYear (toUTCTime (TOD 0 0)), ctYear ct >= 2023)
  t <- getCPUTime
  print (t >= 0)
  performGC

  hSetBuffering stdout NoBuffering
  hPutStr stderr "to stderr\n"
  when (null args) (exitWith (ExitFailure 4))
  exitWith (ExitFailure 5)
