module Main (main) where

import Control.Concurrent.MVar
import System.Exit
import System.Posix.Env
import System.Posix.Files
import System.Posix.IO
import System.Posix.Process
import System.Posix.Signals
import System.IO (hFlush, stdout)

main :: IO ()
main = do
  pid <- getProcessID
  ppid <- getParentProcessID
  print (pid > 0, ppid > 0)
  hFlush stdout
  (r, w) <- createPipe
  child <- forkProcess (fdWrite w "from child" >> exitImmediately (ExitFailure 9))
  (msg, n) <- fdRead r 10
  st <- getProcessStatus True False child
  print (msg, n, st)
  writeFile "f.txt" "12345"
  fs <- getFileStatus "f.txt"
  print (fileSize fs, isRegularFile fs, isDirectory fs)
  setFileMode "f.txt" ownerReadMode
  fs2 <- getFileStatus "f.txt"
  print (fileMode fs2 `intersectFileModes` accessModes == ownerReadMode)
  got <- newEmptyMVar
  installHandler sigUSR1 (Catch (putMVar got "USR1")) Nothing
  raiseSignal sigUSR1
  takeMVar got >>= putStrLn
  setEnv "FOO" "bar" True
  getEnv "FOO" >>= print
