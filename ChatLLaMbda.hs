import Data.Char
import System.IO
import Control.Exception

import LTypes
import LExp
import qualified Lambek

import Parser
import PySupport

import System.Environment (setEnv)
import EvalExpr

-- "standardize" the capitalization of a word by making the first
-- letter uppercase and the following letters lowercase.
-- (This will make it easier to look up words in the lexicon.)
stdize (c:cs) = toUpper c : map toLower cs

-- read-eval-print-loop
repl :: Lexicon PythonCode -> PythonHandle -> IO ()
repl elx phandle = do
  -- print the prompt
  putStr "> "
  -- get a line of input
  line <- getLine
  -- split it up into "standardized" words
  let ws = map stdize $ words line
  -- show possible grammatical structure according to the lexicon
  let structures = Lambek.grammaticalStructure elx ws ++ Lambek.questionStructure elx ws
  let commands = Lambek.commandStructure elx ws

  case (null structures, null commands) of 
    (True, True)  -> putStrLn "Not well-formed" 
    (False, True) -> do
        -- transform lambda expressions to corresponding code => [(LExp, PythonCode)]
        let pycode = translateToCode structures
        -- evaluate Python code with evalMeanings => IO [(LExp, String)]; 
        -- we extract the result [(LExp, String)] using <- 
        meanings <- evalMeanings phandle pycode 
        -- print the meanings => IO()
        printMeanings meanings
    (True, False) -> executeCmd phandle (translateToCode commands)
    (False, False) -> putStrLn "Your input is ambiguous. Please reformulate as either a statement or command. No action was performed."

  {- this was for part 2
  let expressions = map fst structures
  if null expressions
    then putStrLn "That is not a well-formed sentence"
    else mapM_ printLExp expressions
  -}

  {- for testing
  mapM_ (\(expr, code) -> do
    putStrLn ("Lambda expr: " ++ prettyLExp expr)
    putStrLn ("Python: " ++ text code)
    ) pycode
  -}

  -- repeat
  repl elx phandle
      
main = do
  -- send console output immediately to the user
  hSetBuffering stdout NoBuffering
  -- input a lexicon file
  elx <- getLex
  -- input a database of facts
  db <- getDB
  -- clear PYTHONSTARTUP to prevent startup messages (VS Code) from adding unexpected output
  setEnv "PYTHONSTARTUP" ""
  -- launch a Python interpreter
  phandle <- launchPython db
  -- start the read-eval-print loop
  putStrLn "Starting chat..."
  repl elx phandle
  where
    getDB :: IO PythonCode
    getDB = do
      putStr "Facts about the world: "
      dname <- getLine
      mdb <- try (readFile dname) :: IO (Either IOError String)
      case mdb of
        Left err -> putStrLn ("Error loading file " ++ show err) >> getDB
        Right db -> return (PCode db)
      
    getLex :: IO (Lexicon PythonCode)
    getLex = do
      putStr "Lexicon file: "
      lname <- getLine
      res <- parseFile lexicon lname
      case res of
        Left err -> putStrLn ("Error loading file " ++ show err) >> getLex
        Right (Left err) -> putStrLn ("parse error at " ++ lname ++ ":" ++ show err) >> getLex
        Right (Right lex) -> return lex
