{-# LANGUAGE TemplateHaskell #-}

module Quoter
  ( js
  ) where

import Language.Haskell.TH.Quote
import Language.JavaScript.NodeJS.Splices

js :: QuasiQuoter
js = $(makeQuoter)
