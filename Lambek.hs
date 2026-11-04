{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module Lambek where

import LTypes
import LExp

{-
dec_rinv reduces target until it is atomic then passes it to dec_linv with a chosen focus
dec_linv decomposes the focus type and consumes the needed argument from either left 
or right side
-}

{-dec_rinv :: [LTp] -> LTp -> Bool

dec_rinv gamma c "can the list gamma produce the type c"
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

{-
der_inv constructs full lambda expressions
der_inv collects argumenst for its focused type
-}

nested_application :: (LExp, [LExp]) -> LExp
nested_application (v, []) = v
nested_application (v, x : xs) =  nested_application (A v x, xs)

build_focus_applications :: (Var, [[LExp]]) -> [LExp]
build_focus_applications (v, []) = []
build_focus_applications (v, x: xs) = (nested_application (V v, x)) : build_focus_applications (v, xs) 

-- here f :: (Var, LTp)
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

dec_lfoc gammaL f gammaR p = 
if f atomic then f needs to pe the same as p AND gammaL and gammaR must both be empty
--------------
if f divL a b 

    gammaL        gammaR
   [.......] a\b [.......] 

   [....|**] a\b [.......] if we section gammaL at any point, can its rightmost part(gammaL2) produce a?
    |     |
gammaL1  gammaL2

then scope becomes  gammaL1 b gammaR p
----------------
if f divR b a 

    gammaL         gammaR
   [.......] b /a [.......] 

   [.......] b /a [**|....]
		   |    |
               gammaR1  gammaR2
 if we section gammaR at any point, can its leftmost part(gammaR1) produce a?

then scope becomes  gammaL b gammaR2 p

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


combine_possible_derivations :: ([LExp], [[LExp]]) -> [[LExp]]
combine_possible_derivations (xa, xb) = if null xa || null xb 
    then [] 
    else concat [map (\xs -> a : xs) xb | a <- xa]


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


isGrammatical :: Lexicon sem -> [String] -> Bool
isGrammatical lex ws = let possibleTypes = [[a | (word, a, _) <- items lex, word == w] | w <- ws]
                           gammas        = sequence possibleTypes
                       in any(\gamma -> dec_rinv gamma (stp lex)) gammas

create_names :: [String] -> Int -> [String]
create_names [] n = []
create_names (x : xs) n = (x ++ "_" ++ (show n)) : (create_names xs (n + 1)) 

grammaticalStructure :: Lexicon sem -> [String] -> [LExp]
grammaticalStructure lex ws = concat [der_rinv gamma (stp lex) | gamma <- named_gammas]
    where
        new_names = create_names ws 1
        possibleTypes = [[a | (word, a, _) <- items lex, word == w] | w <- ws]
        gammas = sequence possibleTypes
        named_gammas = [zip new_names gamma | gamma <- gammas]


