{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module Lambek where

import LTypes
import LExp

{-
dec_rinv :: [LTp] -> LTp -> Bool
dec_rinv gamma c "can the list gamma produce the type c"

for a division target, it introduces an assumption on the left (for DivL) / right (for DivR)
side and continues reducing the target.

for an atomic target, it tries all possible focus types and calls dec_lfoc.
-}
dec_rinv :: [LTp] -> LTp -> Bool
dec_rinv gamma c =
    case c of
        Atm p    -> any(\i -> let gammaL = take i gamma
                                  f = gamma !! i
                                  gammaR = drop (i + 1) gamma
                              in dec_lfoc gammaL f gammaR p)
                    [0 .. (length gamma - 1)]
        DivL a b -> dec_rinv (a : gamma) b
        DivR b a -> dec_rinv (gamma ++ [a]) b

--helper for created an application with multiple arguments
--nested_application: (f, [u, v]) to (f u) v
nested_application :: (LExp, [LExp]) -> LExp
nested_application (v, []) = v
nested_application (v, x : xs) =  nested_application (A v x, xs)

--helper for creating the nested applications for the variable in focus
--for all the possible structures 
build_focus_applications :: (Var, [[LExp]]) -> [LExp]
build_focus_applications (v, []) = []
build_focus_applications (v, x: xs) = (nested_application (V v, x)) : build_focus_applications (v, xs)

-- der_rinv constructs full lambda expressions for successful derivations

der_rinv :: [(Var,LTp)] -> LTp -> [LExp]
der_rinv gamma c =
    case c of
        Atm p -> concat expressions
            where
                tries = [(take i gamma, gamma !! i, drop (i + 1) gamma)| i <- [0 .. (length gamma - 1)]]
                possibleTypes = [(fst f, der_lfoc gammaL (snd f) gammaR p)| (gammaL, f, gammaR) <- tries]
                expressions = map build_focus_applications possibleTypes

        DivL a b -> [L new_var expr |expr <- expressions]
            where
                var_names = [V (fst elem) | elem <- gamma]
                new_var = fresh var_names
                expressions = der_rinv ((new_var, a) : gamma) b

        DivR b a -> [L new_var expr |expr <- expressions]
            where
                var_names = [V (fst elem) | elem <- gamma]
                new_var = fresh var_names
                expressions = der_rinv (gamma ++ [(new_var , a)]) b

{-
dec_lfoc :: [LTp] -> LTp -> [LTp] -> Atm -> Bool

dec_lfoc decomposes the focus type and consumes the needed argument from either left
or right side

dec_lfoc gammaL f gammaR p =
if f atomic then f needs to be the same as p AND gammaL and gammaR must both be empty
--------------
if f divL a b
is there a split gammaL = gammaL1 ++ gammaL2 st
    gammaL2 -> a and
    gammaL1 [b] gammaR -> p?
----------------
if f divR b a
is there a split gammaR = gammaR1 ++ gammaR2 st
    gammaR1 -> a and
    gammaL [b] gammaR2 -> p?
-}

dec_lfoc :: [LTp] -> LTp -> [LTp] -> Atm -> Bool
dec_lfoc gammaL f gammaR p =
    case f of
        Atm t    -> null gammaL && t == p && null gammaR
        DivL a b -> any(\i -> let gammaL1 = take i gammaL
                                  gammaL2 = drop i gammaL
                              in (dec_rinv gammaL2 a) && (dec_lfoc gammaL1 b gammaR p))
                    [0 .. length gammaL]
        DivR b a -> any(\i -> let gammaR1 = take i gammaR
                                  gammaR2 = drop i gammaR
                              in (dec_rinv gammaR1 a) && (dec_lfoc gammaL b gammaR2 p))
                    [0 .. length gammaR]


{-
combine_possible_derivations combines every possibility of a next arg in xa with
every remaining arg list in xb.
-}

combine_possible_derivations :: ([LExp], [[LExp]]) -> [[LExp]]
combine_possible_derivations (xa, xb) = if null xa || null xb
    then []
    else concat [map (\xs -> a : xs) xb | a <- xa]

{-
der_lfoc constructs possible argument lists for the focused expression
- [] means no success
- [[]] means success needing no args
-}

der_lfoc :: [(Var,LTp)] -> LTp -> [(Var,LTp)] -> Atm -> [[LExp]]
der_lfoc gammaL f gammaR p =
    case f of
        Atm t    -> if null gammaL && t == p && null gammaR then [[]] else []
        DivL a b -> concat expressions_filtered
            where
                tries = [(take i gammaL, drop i gammaL)| i <- [0 .. length gammaL]]
                expressions_not_filtered = [(der_rinv gammaL2 a, der_lfoc gammaL1 b gammaR p)| (gammaL1, gammaL2) <- tries]
                expressions_filtered = map combine_possible_derivations expressions_not_filtered

        DivR b a -> concat expressions_filtered
            where
                tries = [(take i gammaR, drop i gammaR)| i <- [0 .. length gammaR]]
                expressions_not_filtered = [(der_rinv gammaR1 a, der_lfoc gammaL b gammaR2 p)| (gammaR1, gammaR2) <- tries]
                expressions_filtered = map combine_possible_derivations expressions_not_filtered

-- isGrammatical checks grammatical sentence according to lexicon => True / False
isGrammatical :: Lexicon sem -> [String] -> Bool
isGrammatical lex ws = let possibleTypes = [[a | (word, a, _) <- items lex, word == w] | w <- ws]
                           gammas        = sequence possibleTypes
                       in any(\gamma -> dec_rinv gamma (stp lex)) gammas

--adds numbers to the words based on their position in the sentence 
create_names :: [String] -> Int -> [String]
create_names [] n = []
create_names (x : xs) n = (x ++ "_" ++ (show n)) : (create_names xs (n + 1))

-- getSemantics gives a list of (variable, meaning) pairs
getSemantics :: [((Var, LTp), sem)] -> [(Var, sem)]
getSemantics gamma = map (\((v, t), s) -> (v, s)) gamma

{-
grammaticalStructure returns the pairs of grammatical lambda expressions and list of
each word's semantic meaning in the respective expression
-}
grammaticalStructure :: Lexicon sem -> [String] -> [(LExp, [(Var, sem)])]
grammaticalStructure lex ws =
    [(e, semantics)|
        gamma <- named_gammas,
        let expressions = der_rinv (map fst gamma) (stp lex),
        let semantics = getSemantics gamma,
        e <- expressions]
    where
        new_names = create_names ws 1
        possibleTypes = [[(a, sem) | (word, a, sem) <- items lex, word == w] | w <- ws]
        gammas = sequence possibleTypes
        named_gammas = [zipWith (\name (t, s) -> ((name, t), s)) new_names gamma | gamma <- gammas]

{- commandStructure calls grammaticalStructure but instead of the sentence type, 
we want the command type cmd
-}
commandStructure :: Lexicon sem -> [String] -> [(LExp, [(Var, sem)])]
commandStructure lex ws = grammaticalStructure (lex { stp = Atm "cmd" }) ws
