{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

module Main
  ( main
  ) where

import Control.Exception
import Language.JavaScript.NodeJS.Splices
import Quoter

main :: IO ()
main = do
  (eval, quit) <- $(makeEval)
  flip finally quit $ do
    two <- eval "let two = 1 + 1; two"
    print two
    two' <- eval "two"
    print two'
    tmpdir <- eval "require('os').tmpdir()"
    print tmpdir
    let answer = [js| 6 * 7 |]
    print answer
