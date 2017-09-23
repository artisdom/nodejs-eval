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
    two <- eval "let two = 1 + 1; two"
    print two
    two' <- eval "two"
    print two'
    tmpdir <- eval "require('os').tmpdir()"
    print tmpdir
