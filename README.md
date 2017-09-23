# nodejs-eval

[![Build Status](https://travis-ci.org/TerrorJack/nodejs-eval.svg)](https://travis-ci.org/TerrorJack/nodejs-eval)

Execute Node.js scripts in Haskell.

## Usage

### Adding dependency

First, add `nodejs-eval` to the [`custom-setup`](https://cabal.readthedocs.io/en/latest/developing-packages.html#custom-setup-scripts) stanza of your package's `.cabal` config. The `Setup.hs` script looks like:

```haskell
import Language.JavaScript.NodeJS.CabalHook

main :: IO ()
main = defaultMainWithEvalServer pure
```

If you need to add `npm` dependencies, you can add them like this:

```haskell
{-# LANGUAGE OverloadedStrings #-}

import Language.JavaScript.NodeJS.CabalHook

main :: IO ()
main = defaultMainWithEvalServer $ addDependencies [("left-pad", "^1.1.3")]
```

Then, add `nodejs-eval` as a regular dependency for your build target.

### Run-time execution

You can execute Node.js scripts like this:

```haskell
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

import Control.Exception
import Language.JavaScript.NodeJS.Splices

initEvalServer :: IO (Text -> IO Value, IO ())
initEvalServer = $(makeEval)

onePlusOne :: IO ()
onePlusOne = do
  (eval, quit) <- initEvalServer
  flip finally quit $ do
    result <- eval "1 + 1"
    print result
```

Now, executing `initEvalServer` will start the eval server. Two continuations are returned, the first one accepts a Node.js script, and returns the evaluation result as a `Data.Aeson.Value`. Evaluation failure will raise an exception. A eval server has a single V8 execution context, and bindings are shared across `eval` calls. `require` is available.

The second continuation will terminate the eval server. Remember to use `bracket` or similar function to make sure the finalizer is invoked even in case of exception, to prevent dangling `node` processes.

### Compile-time execution

It is also possible to use a quasi-quote to embed a JavaScript snippet in Haskell and retrieve the result at compile time. First, add a `Quoter` module (or `Internal` or whatever) to your package. The module is meant to supply a `QuasiQuoter`:

```haskell
{-# LANGUAGE TemplateHaskell #-}

module Quoter (js) where

import Language.Haskell.TH.Quote

js :: QuasiQuoter
js = $(makeQuoter)
```

Now, inline JavaScript in Haskell is available:

```haskell
{-# LANGUAGE QuasiQuotes #-}

import Data.Aeson
import Quoter

answer :: Value
answer = [| 6 * 7 |]
```

See [`nodejs-eval-test`](nodejs-eval-test) for a complete demo.
