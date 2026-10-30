# Documentation

## Part 1: Checking a sentence is grammatical (Lambek's algorithm)
Implementation in `Lambek.hs`:

1. `dec_rinv` checks whether $\Gamma \rightarrow C$ by distinguishing three cases:

- If $C$ is an atomic type $p$, we check all possibilities of bringing a type into focus using inference rule $F$. We thus call the `dec_lfoc` function to check if there exists one type that we can bring into focus so that the premise is true.

```math
\frac{\Gamma_L[A]\Gamma_R \longrightarrow p}
{\Gamma_L,A,\Gamma_R \longrightarrow p}\;F
```

- If $C$ is a left division $A \backslash B$, we use inference rule $R$.


```math
\frac{A,\Gamma \longrightarrow B}{\Gamma \longrightarrow A\backslash B}\;R
```

- If $C$ is a right division $B/A$, we use inference rule $R'$.

```math
\frac{\Gamma,A \longrightarrow B}{\Gamma \longrightarrow B/A}\;R'
```

2. `dec_lfoc` checks whether $\Gamma_L[F]\Gamma_R \longrightarrow p$ for $F$ being a type in focus. We distinguish three cases again:

- If $F$ is an atomic type $t$, we need that $\Gamma_L$ and $\Gamma_R$ must be empty and $t$ must be equal to $p$ by the axiom $X$.

```math
\frac{}{[p]\longrightarrow p}\;X
```

- If $F$ is a left division $A \backslash B$, we check if any of the possible splits $\Gamma_L = \Gamma_{L1}, \Gamma_{L2}$ are such that we can use the right half $\Gamma_{L2}$ to derive $A$ and the left half $\Gamma_{L1}$, with focus $B$ and remaining types $\Gamma_R$ to derive $p$ and apply inference rule $L$.

```math
\frac{
\Gamma_{L2}\longrightarrow A
\qquad
\Gamma_{L1}[B]\Gamma_R\longrightarrow p
}{
\Gamma_{L1},\Gamma_{L2}[A\backslash B]\Gamma_R\longrightarrow p
}\;L
```

- If $F$ is a right division $B/A$, we check if any of the possible splits $\Gamma_R = \Gamma_{R1}, \Gamma_{R2}$ are such that we can apply inference rule $L'$.

```math
\frac{
\Gamma_{R1}\longrightarrow A
\qquad
\Gamma_L[B]\Gamma_{R2}\longrightarrow p
}{
\Gamma_L[B/A]\Gamma_{R1},\Gamma_{R2}\longrightarrow p
}\;L'
```

3. `isGrammatical`
    - First, we iterate over `items lex` and find all possible types of each word in `ws`.
    - Then, we use the Haskell function `sequence` to obtain all possible combinations of these types while keeping the order of the words.
    - Finally, we check if there exist such a combination of types, call it $\Gamma$ that forms a sentence, i.e. that has the type `stp lex`, using the function `dec_rinv`.