module EvalExpr where

import LExp
import PySupport

{- extractCode looks for a name inside a list of (Var, PythonCode) and returns 
its corresponding code
- [] means entry wasn't found, so the corresponding code is PCode x
-}

extractCode :: [(Var, PythonCode)] -> Var -> PythonCode
extractCode [] v = PCode v
extractCode (entry : env) v = if fst entry == v then snd entry
                                              else extractCode env v

{- interpret uses an environment [(Var, PythonCode)] to obatin the Python code 
corresponding to a lambda expression
-}
interpret :: [(Var, PythonCode)] -> LExp -> PythonCode
interpret env expr =
    case expr of
        V v -> extractCode env v
        A e1 e2 ->PCode ('(' : code1 ++ ")(" ++ code2 ++ ")")
            where
                code1 = text (interpret env e1)
                code2 = text (interpret env e2)
        L x e -> PCode ("lambda " ++ x ++ ": " ++ code)
            where
                code = text (interpret env e)

{- translateToCode translates all possible meanings of a sentence to code 
-}
translateToCode :: [(LExp, [(Var, PythonCode)])] -> [(LExp, PythonCode)]
translateToCode xs = [(expr, interpret env expr) |(expr, env) <- xs]

-- takes a pair (lambda expression, corresponding code) and returns the pair 
-- (same lambda expression, the answer from Python)
evalMeaning :: PythonHandle -> (LExp, PythonCode) -> IO (LExp, String)
evalMeaning handle (lexp, code) = do
    answer <- runPythonCode handle code
    return (lexp, answer)

-- takes the list of all possible meanings of a sentence and evaluates them using evalMeaning
-- since we recurse, need the empty list base case
evalMeanings :: PythonHandle -> [(LExp, PythonCode)] -> IO [(LExp, String)]
evalMeanings handle [] = return []
evalMeanings handle ((lexp, code) : tail) = do 
    curr_pair <- evalMeaning handle (lexp, code)
    tail_pairs <- evalMeanings handle tail
    return (curr_pair : tail_pairs)

-- helper for when a sentence has multiple senses: prints the answer given by Python for each sense
printMultipleSenses :: [(LExp, String)] -> IO()
printMultipleSenses [] = return ()
printMultipleSenses ((lexp, answer) : tail) = do
    putStrLn("Sense [" ++ prettyLExp(lexp) ++ "]: " ++ answer)
    printMultipleSenses tail

-- prints the evaluated meanings of a sentence.
-- if a sentence has multiple possible senses, prints each lambda expression and its answer.
printMeanings :: [(LExp, String)] -> IO () 
printMeanings meanings = case meanings of
    [] -> putStrLn "That is not a well-formed sentence"
    [(lexp, answer)] -> putStrLn answer
    sense_list -> do
        putStrLn "That sentence is ambiguous"
        printMultipleSenses sense_list

-- given all possible meanings of a command, either executes it or reports ambiguity
executeCmd :: PythonHandle -> [(LExp, PythonCode)] -> IO ()
executeCmd handle [] = return ()
executeCmd handle [(expr, code)] = do 
    let codeToPrint = PCode ("print( " ++ text code ++ ")")
    (_, answer) <- evalMeaning handle (expr, codeToPrint)
    putStrLn answer
executeCmd handle commands = do
    putStrLn "That command is ambigous. No action was performed."