module EvalExpr where

import LExp
import PySupport

-- takes a pair (expression, corresponding code) and returns the pair 
-- (same expression, the answer from Python)
evalMeaning :: PythonHandle -> (LExp, PythonCode) -> IO (LExp, String)
evalMeaning handle (lexp, code) = do
    answer <- runPythonCode handle code
    return (lexp, answer)

-- takes the list of all possible meanings and evaluates them using evalMeaning
-- since we recurse, need the empty list base case
evalMeanings :: PythonHandle -> [(LExp, PythonCode)] -> IO [(LExp, String)]
evalMeanings handle [] = return []
evalMeanings handle ((lexp, code) : tail) = do 
    curr_pair <- evalMeaning handle (lexp, code)
    tail_pairs <- evalMeanings handle tail
    return (curr_pair : tail_pairs)

-- helper for when an expression has multiple senses: prints the answer given by Python for each sense
printMultipleSenses :: [(LExp, String)] -> IO()
printMultipleSenses [] = return ()
printMultipleSenses ((lexp, answer) : tail) = do
    putStrLn("Sense [" ++ prettyLExp(lexp) ++ "]: " ++ answer)
    printMultipleSenses tail

-- prints the answer given by Python for each expression in a list
-- representing the meanings of a sentence. 
-- if an expression has multiple possible senses, treats all cases
printMeanings :: [(LExp, String)] -> IO () 
printMeanings meanings = case meanings of
    [] -> putStrLn "That is not a well-formed sentence"
    [(lexp, answer)] -> putStrLn answer
    sense_list -> do
        putStrLn "That sentence is ambiguous"
        printMultipleSenses sense_list