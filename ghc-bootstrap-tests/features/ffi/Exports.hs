module Exports where

import Foreign.C

foreign export ccall triple :: CInt -> IO CInt
foreign export ccall "hs_concat_len" concatLen :: CInt -> IO CInt

triple :: CInt -> IO CInt
triple x = return (3 * x)

concatLen :: CInt -> IO CInt
concatLen n = return (fromIntegral (length (concat (replicate (fromIntegral n) "abc"))))
