-- |
-- Module:     Trace.Hpc.Codecov.Exception
-- Copyright:  (c) 2022 8c6794b6
-- License:    BSD3
-- Maintainer: 8c6794b6 <8c6794b6@gmail.com>
--
-- Error and exception related codes.

module Trace.Hpc.Codecov.Exception
  (
    -- * Exception data type and handler
    HpcCodecovError(..)
  , withBriefUsageOnError
  ) where

-- base
import Control.Exception  (Exception (..), handle)
import System.Environment (getProgName)
import System.Exit        (exitFailure)

-- | Run the given action with a handler for 'HpcCodecovError'.
--
-- The handler will show a brief usage and call 'exitFailure' when an
-- exception was caught.
withBriefUsageOnError :: IO a   -- ^ Action to perform.
                      -> IO a
withBriefUsageOnError = handle handler
  where
    handler :: HpcCodecovError -> IO a
    handler e =
      do putStr ("Error: " ++ displayException e)
         name <- getProgName
         putStrLn ("Run '" ++ name ++ " --help' for usage.")
         exitFailure

-- | Exceptions thrown during coverage report generation.
data HpcCodecovError
  = NoTarget
   -- ^ Target was not given.
  | TixNotFound FilePath
   -- ^ Tix file path was given, but not found.
  | MixNotFound FilePath [FilePath]
   -- ^ Mix file not found. The first field is the path specified by a
   -- tix file. The second is the searched paths.
  | SrcNotFound FilePath [FilePath]
   -- ^ Like 'MixNotFound', but for source code specified by a mix
   -- file.
  | InvalidBuildTool String
   -- ^ Invalid build tool.
  | InvalidFormat String
   -- ^ Invalid report format.
  | TestSuiteNotFound String
   -- ^ Test suite was given, but not found.
  | InvalidArgs [String]
   -- ^ Some errors in command line argument, e.g., required value not
   -- specified.
  deriving (Show)

instance Exception HpcCodecovError where
  displayException = hpcCodecovErrorMessage

hpcCodecovErrorMessage :: HpcCodecovError -> String
hpcCodecovErrorMessage e =
  case e of
    NoTarget -> "no TARGET was given\n"
    TixNotFound tix -> "cannot find tix: " ++ show tix ++ "\n"
    MixNotFound mix locs -> searchedLocations "mix" mix locs
    SrcNotFound src locs -> searchedLocations "src" src locs
    InvalidBuildTool tool-> "invalid build tool: `" ++ tool ++ "'\n"
    InvalidFormat fmt -> "invalid format: `" ++ fmt ++ "'\n"
    TestSuiteNotFound name ->
      "cannot find tix for test suite: " ++ show name ++ "\n"
    InvalidArgs msgs ->
      case msgs of
        [x] -> x
        _   -> '\n' : concatMap ("  - " ++) msgs

searchedLocations :: String -> FilePath -> [FilePath] -> String
searchedLocations what path locs =
  "cannot find " ++ what ++ ": " ++ show path ++ locs'
  where
    locs' =
      case locs of
       [_] -> searched ""
       _   -> searched "s"
    searched post =
      "\nsearched location" ++ post ++ ":\n" ++
      unlines (map ("  " ++) locs)
