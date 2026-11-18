module Main (main) where

import Prelude hiding (catch)
import Control.Concurrent
import Control.Exception
import Control.Monad (replicateM_)
import System.Time

main :: IO ()
main = do
  -- 1000 threads increment a shared counter
  counter <- newMVar (0 :: Int)
  done <- newEmptyMVar
  mapM_ (\_ -> forkIO (modifyMVar_ counter (return . (+ 1)) >> putMVar done ())) [1 .. 1000 :: Int]
  replicateM_ 1000 (takeMVar done)
  readMVar counter >>= print

  -- A pipeline through two channels
  c1 <- newChan
  c2 <- newChan
  forkIO (mapM_ (writeChan c1) [1 .. 100 :: Int])
  forkIO (replicateM_ 100 (readChan c1 >>= writeChan c2 . (* 2)))
  xs <- mapM (const (readChan c2)) [1 .. 100 :: Int]
  print (sum xs)

  -- Threads wake in the order of their delays
  out <- newMVar []
  fin <- newEmptyMVar
  mapM_ (\d -> forkIO (threadDelay (d * 50000) >> modifyMVar_ out (return . (d :)) >> putMVar fin ())) [3, 1, 2 :: Int]
  replicateM_ 3 (takeMVar fin)
  readMVar out >>= print . reverse

  -- killThread raises ThreadKilled in the target, which can catch it
  res <- newEmptyMVar
  t <- forkIO (catch (threadDelay 10000000 >> putMVar res "not killed") (\e -> putMVar res ("caught: " ++ show e)))
  threadDelay 10000
  killThread t
  takeMVar res >>= putStrLn

  -- throwTo with an arbitrary exception
  res2 <- newEmptyMVar
  t2 <- forkIO (catch (threadDelay 10000000 >> putMVar res2 "not thrown") (putMVar res2 . show))
  threadDelay 10000
  throwTo t2 (ErrorCall "custom")
  takeMVar res2 >>= putStrLn

  -- Blocked on an MVar that no other thread can fill
  r <- try (newEmptyMVar >>= \m -> takeMVar (m :: MVar ()))
  putStrLn
    ( case r of
        Left BlockedOnDeadMVar -> "deadlock detected"
        Left e -> "other: " ++ show e
        Right () -> "no deadlock"
    )

  -- threadDelay waits at least as long as asked
  t0 <- getClockTime
  threadDelay 200000
  t1 <- getClockTime
  let d = diffClockTimes t1 t0
      us = toInteger (tdSec d) * 1000000 + tdPicosec d `div` 1000000
  print (us >= 200000 && us < 5000000)

  -- yield lets a waiting thread run
  flag <- newEmptyMVar
  forkIO (putMVar flag "yielded")
  yield
  takeMVar flag >>= putStrLn
  tid <- myThreadId
  print (tid == tid)
