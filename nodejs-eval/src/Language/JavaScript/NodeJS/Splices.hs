{-# LANGUAGE TemplateHaskell #-}

module Language.JavaScript.NodeJS.Splices
  ( splice
  , typedSplice
  ) where

import Data.Aeson
import qualified Data.HashMap.Strict as HM
import qualified Data.Text as T
import GHC.IO.Handle
import Language.Haskell.TH.Syntax
import Language.JavaScript.NodeJS.CabalHook.Splices
import Network.HTTP.Simple
import Network.HTTP.Types
import System.FilePath
import System.Process

splice :: Q Exp
splice =
  [|do (_, Just h_stdout, _, h) <-
         createProcess
           ((proc "node" ["server.js"])
            {cwd = Just ($(datadirQ) </> "jsbits"), std_out = CreatePipe})
       port_line <- hGetLine h_stdout
       initReq <- parseRequest "http://localhost/eval"
       let req =
             setRequestMethod methodPost $
             setRequestPort (read port_line) initReq
       pure
         ( \code -> do
             resp <-
               httpJSON $
               setRequestBodyJSON
                 (Object $ HM.singleton (T.pack "code") (String code))
                 req
             case getResponseBody resp of
               Object obj ->
                 case HM.lookup (T.pack "success") obj of
                   Just v -> pure v :: IO Value
                   _ -> fail $ "evaluation failed: " ++ show resp
               _ -> fail $ "illegal response: " ++ show resp
         , terminateProcess h)|]

typedSplice :: Q (TExp (IO (T.Text -> IO Value, IO ())))
typedSplice = unsafeTExpCoerce splice
