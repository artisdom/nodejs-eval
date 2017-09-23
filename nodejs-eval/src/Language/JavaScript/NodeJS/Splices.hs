{-# LANGUAGE TemplateHaskell #-}

module Language.JavaScript.NodeJS.Splices
  ( makeEval
  , makeEvalTyped
  , makeQuoter
  , makeQuoterTyped
  ) where

import Data.Aeson
import qualified Data.ByteString.Char8 as BS
import qualified Data.HashMap.Strict as HM
import qualified Data.Text as T
import GHC.IO.Handle
import Language.Haskell.TH.Quote
import Language.Haskell.TH.Syntax
import Language.JavaScript.NodeJS.CabalHook.Splices
import Network.HTTP.Client
import Network.HTTP.Types
import System.FilePath
import System.Process

makeEval :: Q Exp
makeEval =
  [|do (_, Just h_stdout, _, h) <-
         createProcess
           ((proc "node" ["server.js"])
            {cwd = Just ($(datadirQ) </> "jsbits"), std_out = CreatePipe})
       port_line <- hGetLine h_stdout
       initReq <- parseRequest "http://localhost/eval"
       let req =
             initReq
             { method = methodPost
             , port = read port_line
             , requestHeaders =
                 [ (hAccept, BS.pack "application/json")
                 , (hContentType, BS.pack "application/json; charset=utf-8")
                 ]
             , cookieJar = Nothing
             }
       mgr <- newManager defaultManagerSettings
       pure
         ( \code -> do
             resp <-
               httpLbs
                 req
                 { requestBody =
                     RequestBodyLBS $
                     encode $
                     Object $ HM.singleton (T.pack "code") (String code)
                 }
                 mgr
             case eitherDecode' $ responseBody resp of
               Right (Object obj) ->
                 case HM.lookup (T.pack "success") obj of
                   Just v -> pure v :: IO Value
                   _ -> fail $ "evaluation failed: " ++ show obj
               _ -> fail $ "illegal response: " ++ show resp
         , terminateProcess h)|]

makeEvalTyped :: Q (TExp (IO (T.Text -> IO Value, IO ())))
makeEvalTyped = unsafeTExpCoerce makeEval

makeQuoter :: Q Exp
makeQuoter =
  [|QuasiQuoter
    { quoteExp =
        \code -> do
          r <- qGetQ
          eval <-
            case r of
              Just eval -> pure eval
              _ -> do
                (eval, quit) <- runIO $(makeEval)
                qAddModFinalizer $ runIO quit
                qPutQ eval
                pure eval
          r' <- runIO $ eval $ T.pack code
          lift r'
    , quotePat = undefined
    , quoteType = undefined
    , quoteDec = undefined
    }|]

makeQuoterTyped :: Q (TExp QuasiQuoter)
makeQuoterTyped = unsafeTExpCoerce makeQuoter
