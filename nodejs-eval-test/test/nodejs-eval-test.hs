{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Main
  ( main
  ) where

import Control.Exception
import Language.JavaScript.NodeJS.Splices

main :: IO ()
main = do
  (eval, quit) <- $(splice)
  flip finally quit $ do
    result <- eval "1 + 1"
    print result
