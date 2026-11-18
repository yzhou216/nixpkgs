module Main (main) where

import Control.Concurrent
import Network.Socket

-- A server thread and a client on the loopback interface
main :: IO ()
main = do
  s <- socket AF_INET Stream 0
  setSocketOption s ReuseAddr 1
  addr <- inet_addr "127.0.0.1"
  bindSocket s (SockAddrInet aNY_PORT addr)
  listen s 1
  port <- socketPort s
  done <- newEmptyMVar
  forkIO
    ( do
        (c, _) <- accept s
        msg <- recv c 100
        send c (reverse msg)
        sClose c
        putMVar done ()
    )
  c <- socket AF_INET Stream 0
  connect c (SockAddrInet port addr)
  send c "ping"
  recv c 100 >>= putStrLn
  takeMVar done
  sClose c
  sClose s
