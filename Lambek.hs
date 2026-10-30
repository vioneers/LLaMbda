{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module Lambek where

import LTypes

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

isGrammatical :: Lexicon sem -> [String] -> Bool
isGrammatical lex ws = let possibleTypes = [[a | (word, a, _) <- items lex, word == w] | w <- ws]
                           gammas        = sequence possibleTypes
                       in any(\gamma -> dec_rinv gamma (stp lex)) gammas
