{-# OPTIONS -fglasgow-exts #-}
module Main (main) where

import Foreign
import Foreign.C

foreign import ccall unsafe "math.h sin" c_sin :: CDouble -> CDouble
foreign import ccall unsafe "string.h strlen" c_strlen :: CString -> IO CSize
foreign import ccall "cbits.h add3" add3 :: CInt -> CInt -> CInt -> CInt
foreign import ccall "cbits.h dot" dot :: Ptr CDouble -> Ptr CDouble -> CInt -> IO CDouble
foreign import ccall "cbits.h fill" fill :: Ptr CInt -> CInt -> IO ()
foreign import ccall "cbits.h mix" mix :: CLLong -> CULLong -> CInt -> CUChar -> CDouble -> CFloat -> CLLong
foreign import ccall "cbits.h &twice" p_twice :: FunPtr (CInt -> CInt)
foreign import ccall "dynamic" callIntFun :: FunPtr (CInt -> CInt) -> CInt -> CInt

main :: IO ()
main = do
  print (c_sin 0, c_sin (pi / 2))
  withCString "hello, world" c_strlen >>= print
  print (add3 1 2 (-3))
  withArray [1, 2, 3] (\a -> withArray [4, 5, 6] (\b -> dot a b 3)) >>= print
  allocaArray 5 (\p -> fill p 5 >> peekArray 5 p) >>= print
  print (mix (-1000000000000) (2 ^ 63) 7 255 2.9 (-1.5))
  print (callIntFun p_twice 21)
  fp <- mallocForeignPtrArray 10 :: IO (ForeignPtr Word32)
  withForeignPtr fp (\p -> mapM_ (\i -> pokeElemOff p i (fromIntegral (i * i))) [0 .. 9] >> peekArray 10 p) >>= print
  print (sizeOf (undefined :: CInt), sizeOf (undefined :: CLong), sizeOf (undefined :: Ptr ()), sizeOf (undefined :: Int), alignment (undefined :: Int64))
  p <- mallocBytes 64
  fp2 <- newForeignPtr finalizerFree (p :: Ptr Word8)
  withForeignPtr fp2 (\q -> pokeByteOff q 63 (7 :: Word8) >> peekByteOff q 63) >>= (print :: Word8 -> IO ())
  with (12345 :: Int32) peek >>= print
  alloca (\q -> poke q (3.5 :: Double) >> peek q) >>= print
  print ((nullPtr `plusPtr` 8 :: Ptr Word8) `minusPtr` (nullPtr :: Ptr ()))
  cs <- newCString "round trip"
  peekCString cs >>= putStrLn
  free cs
  sp <- newStablePtr "stable pointer"
  deRefStablePtr sp >>= putStrLn
  freeStablePtr sp
