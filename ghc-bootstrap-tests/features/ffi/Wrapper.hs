{-# OPTIONS -fglasgow-exts #-}
module Main (main) where

import Foreign
import Foreign.C

foreign import ccall "wrapper" mkCallback :: (CInt -> CInt) -> IO (FunPtr (CInt -> CInt))
foreign import ccall "dynamic" callIntFun :: FunPtr (CInt -> CInt) -> CInt -> CInt

main :: IO ()
main = do
  f <- mkCallback (+ 1)
  print (callIntFun f 41)
