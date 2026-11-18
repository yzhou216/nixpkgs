module System (ExitCode (..), getArgs, getProgName, getEnv, system, exitWith, exitFailure) where

import System.Environment (getArgs, getEnv, getProgName)
import System.Exit (ExitCode (..), exitFailure, exitWith)
import System.Process (system)
