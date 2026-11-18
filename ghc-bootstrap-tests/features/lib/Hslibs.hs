module Main (main) where

-- The hslibs compatibility packages: lang, concurrent, util, data, text,
-- posix, net and hssource
import Bits (shiftL, (.&.))
import Concurrent (forkIO, newEmptyMVar, putMVar, takeMVar)
import FiniteMap
import GetOpt
import HsParser (parseModule)
import IOExts (newIORef, readIORef, writeIORef)
import Language.Haskell.Parser (ParseResult (..))
import Posix (getProcessID)
import Pretty (nest, render, text, ($$), (<+>))
import RegexString (matchRegex, mkRegex)
import URI (authority, parseURI, path, scheme)
import Word (Word8)

data Flag = Verbose | Name String deriving (Show, Eq)

options :: [OptDescr Flag]
options =
  [ Option ['v'] ["verbose"] (NoArg Verbose) "verbose"
  , Option ['n'] ["name"] (ReqArg Name "NAME") "name"
  ]

main :: IO ()
main = do
  r <- newIORef (1 :: Int)
  readIORef r >>= writeIORef r . (`shiftL` 4)
  readIORef r >>= print
  print (fromIntegral (300 :: Int) :: Word8, (0xff :: Int) .&. 0x0f)
  m <- newEmptyMVar
  forkIO (putMVar m "from thread")
  takeMVar m >>= putStrLn
  let fm = listToFM [(k, length k) | k <- ["one", "three", "five"]]
  print (lookupFM fm "three", lookupFM fm "two", fmToList fm)
  let (flags, rest, errs) = getOpt Permute options ["-v", "file", "--name=x"]
  print (flags, rest, errs)
  putStrLn (render (text "a" <+> text "b" $$ nest 2 (text "c")))
  print (matchRegex (mkRegex "a(b+)c") "xabbbcx")
  pid <- getProcessID
  print (pid > 0)
  case parseURI "http://www.haskell.org/ghc?q#f" of
    Just u -> print (scheme u, authority u, path u)
    Nothing -> putStrLn "no URI"
  case parseModule "module M where\nx = 1\n" of
    ParseOk _ -> putStrLn "hssource ok"
    ParseFailed _ e -> putStrLn e
