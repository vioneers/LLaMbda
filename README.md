# Documentation
## Building and running
- Compilation: `ghc -package process ChatLLaMbda.hs -o ChatLLaMbda`
- Launching the executable: `./ChatLLaMbda`
- Lexicon file: `animals.elx`
- Facts about the world: `aniworld.py`

## Part 1: Checking a sentence is grammatical (Lambek's algorithm)
#### Implementation in `Lambek.hs`:

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
    - Finally, we check if there exists such a combination of types, call it $\Gamma$, that forms a sentence, i.e. that has the type `stp lex`, using the function `dec_rinv`.

## Part 2:
This part adapts the functions we saw in Part 1, `dec_rinv` and `dec_lfoc`, such that they return all possible grammatical structures instead of just whether or not the sentence is grammatical.  

We created a few helper functions to simplify code inside the main functions:
- `nested_application`: takes an expression and a list of arguments, and creates a left-associative application with all arguments
- `build_focus_applications`: creates the applications for all possible lists of arguments returned by `der_lfoc`
- `combine_possible_derivations`: combines each possible argument with each possible continuation of the derivation
- `create_names`: modifies each string from the list to also store its list position by appending "_i", where i is the position
- `getSemantics`: extracts the names and semantic values associated with each variable 

The three main functions implemented are:
- `der_rinv`: follows the same logic as `dec_rinv`, but generates all possible lambda expressions
- `der_lfoc`: follows the same logic as `dec_lfoc`, but returns all possible lists of arguments
- `grammaticalStructure`: this is the adapted version of `isGrammatical`. It generates all possible grammatical structures of a sentence with the help of `der_rinv` and `der_lfoc`

We modified the REPL to print all generated lambda expressions on separate lines, but this is later changed to print the evaluation of the sentence done in Part 3.

## Part 3: 
### a: Transforming lambda expressions into Python code

This part translates the lambda expressions generated in Part 2 into Python code that is later used in Part 3b to be evaluated.

We added the following functions in `EvalExpr.hs`:

- `extractCode`: searches for a variable in the semantic environment and returns its corresponding Python code. If the variable is not found, it keeps the variable name, since it may have been introduced by a lambda abstraction.
- `interpret`: recursively translates an `LExp` into `PythonCode`, handling the three constructors:
  - `V`: retrieves the variable's Python semantics using `extractCode`
  - `A`: translates both expressions and constructs a Python function application
  - `L`: translates the body and constructs a Python lambda abstraction
- `translateToCode`: applies `interpret` to every lambda expression produced by `grammaticalStructure` using its corresponding semantic environment, producing a list of `(LExp, PythonCode)` pairs.

### b: Evaluating the Python code 
This part receives the possible meanings of a sentence as `[(LExp, PythonCode)]` - pairs of lambda expression and corresponding Python code.

Before integration, we first tested and validated this component independently by manually writing Python code corresponding to the different semantic meanings of some sentences. (see Testing Protocol)

#### Implementation in `EvalExpr.hs`:
- Python evaluation: 
1. `evalMeaning :: PythonHandle -> (LExp, PythonCode) -> IO (LExp, String)` (helper)
2. `evalMeanings :: PythonHandle -> [(LExp, PythonCode)] -> IO [(LExp, String)]`

We use `runPythonCode` to evaluate the PythonCode corresponding to each possible meaning of a sentence. 

- Printing: 
3. `printMultipleSenses :: [(LExp, String)] -> IO()` (helper)
4. `printMeanings :: [(LExp, String)] -> IO ()`

In the case of a single meaning, we only print its evaluation result.
In the case of multiple meanings, we print an ambiguity message and the result of each possible lambda expression corresponding to a different meaning. Even if all meanings evaluate to the same result, we still say the sentence is ambiguous, as different lambda expressions are possible.
If the list of meanings is empty, we conclude that the sentence is not well-formed (according to the given lexicon).

### c: Wiring up in repl 
- Finally, we wire everything up in the read-eval-print-loop in `ChatLLaMbda.hs`:
    - `Lambek.grammaticalStructure elx ws` produces a list of pairs (lambda expression, environment mapping word to its Python code), representing the possible meanings of a sentence;
    - `translateToCode` translates each expression (using its env) => `[(LExp, PythonCode)]`;
    - evaluate the generated code using `evalMeanings` (that uses the running Python interpreter) and print the results with `printMeanings`.

#### Change to `ChatLLaMbda.hs`: 

Before calling `launchPython`, we clear `PYTHONSTARTUP` using `setEnv`. We do that because during initial testing, we noticed that otherwise, a startup message from VS Code was incorrectly interpreted as an evaluation output. This shifted the actual answers and led to incorrect outputs. Clearing `PYTHONSTARTUP` solved this issue.

## Testing protocol (before extensions)
| Sentence | Lambda expression | Python code | Evaluation |
|---|---|---|---|
| Seamus sleeps and Seamus is grey | `And_3 (Sleeps_2 Seamus_1) (Is_5 Seamus_4 Grey_6)` | `((lambda x : lambda y : x and y)((lambda x : x in sleep)('Seamus')))(((lambda x : lambda p : p(x))('Seamus'))(lambda x : x in grey))` | `True` |
| Conor sleeps | `Sleeps_2 Conor_1` | `(lambda x : x in sleep)('Conor')` | `False` |
| every cat sleeps | `Every_1 Cat_2 (\a. Sleeps_3 a)` | `((lambda q : lambda p : all (p(x) for x in animals if q(x)))(lambda x : kind[x] == 'cat'))(lambda a: (lambda x : x in sleep)(a))` | `False` |
| every grey cat sleeps | `Every_1 (Grey_2 Cat_3) (\a. Sleeps_4 a)` | `((lambda q : lambda p : all (p(x) for x in animals if q(x)))((lambda p : lambda x : p(x) and x in grey)(lambda x : kind[x] == 'cat')))(lambda a: (lambda x : x in sleep)(a))` | `True` | 
| every cat fears a dog: sense 1 | `Every_1 Cat_2 (\a. A_4 Dog_5 (\b. Fears_3 a b))` | `((lambda q : lambda p : all (p(x) for x in animals if q(x)))(lambda x : kind[x] == 'cat'))(lambda a: ((lambda q : lambda p : any (p(x) and q(x) for x in animals))(lambda x : kind[x] == 'dog'))(lambda b: ((lambda x : lambda y : (x,y) in fear)(a))(b)))` | `Sense [Every_1 Cat_2 (\a. A_4 Dog_5 (\b. Fears_3 a b))]: True` |
| every cat fears a dog: sense 2 | `A_4 Dog_5 (\a. Every_1 Cat_2 (\b. Fears_3 b a))` | `((lambda q : lambda p : any (p(x) and q(x) for x in animals))(lambda x : kind[x] == 'dog'))(lambda a: ((lambda q : lambda p : all (p(x) for x in animals if q(x)))(lambda x : kind[x] == 'cat'))(lambda b: ((lambda x : lambda y : (x,y) in fear)(b))(a)))` | `Sense [A_4 Dog_5 (\a. Every_1 Cat_2 (\b. Fears_3 b a))]: False` |
| Seamus is hungry and grey | `Is_2 Seamus_1 (And_4 Hungry_3 Grey_5)` | `((lambda x : lambda p : p(x))('Seamus'))(((lambda p : lambda q : lambda x : p(x) and q(x))(lambda x : x in hungry))(lambda x : x in grey))` | `False` | 
| someone fears Fiona | `Someone_1 (\a. Fears_2 a Fiona_3)` | `(lambda p : any (p(x) for x in animals))(lambda a: ((lambda x : lambda y : (x,y) in fear)(a))('Fiona'))` | `True` | 

For ambiguous sentences, the program also prints `That sentence is ambiguous` before the sense results.

## Going Beyond

### 1. New Knowledge Domain - University terms

We added a new knowledge domain of university terms. We implemented those in the following files: `university.elx` and `uniworld.py`, following closely the structure of the already provided `animals.elx` and `aniworld.py`. We use them by typing `university.elx` and `uniworld.py` at the prompts in the terminal.

- we created entities: students, universities, and courses.
- we added adjectives for each entity type: Smart and Tired for students, Challenging and Easy for courses, and Selective and Expensive for universities.
- we added both simple verbs such as graduates and transitive verbs like failed and passed.
- we kept the quantifiers and conjunctions provided by the sample code to compose more complex sentences.
- we used the same grammatical types and derivation algorithm as in the sample code for further integration to be smoother.

Examples:
- `Teodora Studies Compilers`
- `Every Student Attends A University`

### 2. Support for Questions

We extended the interface to support simple questions by adding `Who` and `Which` to the university and animals lexicons.

- `Who` takes a predicate and returns the people satisfying it.
- `Which` takes a noun and a predicate and returns the entities satisfying both.
- questions get their own atomic type `q` (e.g. `Who : q / (np \ s)`), and `questionStructure` in `Lambek.hs` searches for derivations of type `q`, in the same way `commandStructure` does for `cmd`;
- this avoids meaningless answers: with type `s`, `Who Studies A Challenging Course` also had a reading that returned `True` instead of a list of people. 

Examples:
- `Who Studies Compilers`
- `Which Course Is Challenging`

### 3. Support for Imperative Sentences

- We also added support for imperative sentences i.e. commands that modify the state of the running Python world. 

- Commands have grammatical type `cmd`. 
- We added Python action functions in `aniworld.py` and `uniworld.py`. For example, feeding removes an animal from the `hungry` set, while enrolment adds a person to the `students` and `first_year` sets, and graduating removes a person from the `students` and `final_year` sets and adds the person to the `graduates` set. The changes reset when we restart the program.
- `commandStructure` calls the existing `grammaticalStructure` with `cmd` as its target. 
- In `repl`, we now recognize statements and commands separately. We use `executeCmd` to execute the command only when it has exactly one meaning. Ambiguous commands result in no action being performed.

Below is a demonstration (the rows are executed sequentially in this order to get these results):

- `university.elx` / `uniworld.py`:

| Input | Output |
|---|---|
| `Graduate Sarah` | Sarah is not a student |
| `Enroll Sarah` | Enrolled Sarah |
| `Advance Sarah` | Advanced Sarah to second year at unknown university |
| `Advance Sarah` | Advanced Sarah to third (final) year at unknown university |
| `Advance Sarah` | Graduated Sarah from unknown university |
| `Which student is smart and freshman` | `['Villads']` |
| `Advance Villads` | Advanced Villads to second year at MIT |
| `Graduate Villads` | Villads not in final year of studies |
| `Advance Villads` | Advanced Villads to third (final) year at MIT |
| `Graduate Villads` | Graduated Villads from MIT |
| `Graduate Teodora` | Graduated Teodora from ETH |
| `Who is freshman and tired` | `['Nadia']` |

- `animals.elx` / `aniworld.py`:

| Input | Expected output |
|---|---|
| `Conor is hungry` | `True` |
| `Feed Conor` | Fed Conor |
| `Conor is hungry` | `False` |
| `Feed Conor` | Conor not hungry |
| `Which cat is hungry` | `[]` |
| `Seamus sleeps` | `True` |
| `Wake Seamus` | Woke up Seamus |
| `Seamus sleeps` | `False` |
| `Wake Seamus` | Seamus already awake |
| `Conor sleeps` | `False` |
| `Wake Conor` | Conor already awake |
| `Conor sleeps` | `False` |

## Limitations:
- We accept only words and constructions defined in the given lexicon.
- Conjunctions are limited: The conjunction `And` doesn't support sentences like `Maria And Teodora Study Functional` or `Maria Studies Functional And Compilers`. They require another structure for the conjunction `And`. The first type of sentence would also require an adaptation for plural and singular verbs as `Maria And Teodora Studies` is grammatically incorrect in English. 
- Questions: We assume the sentences received don't have any sort of punctuation. Answers are displayed as Python lists. Questions are about the subject: `Who studies analysis` or `Which student is tired`. Questions such as `Which course does Maria study` are not accepted.
- Imperative sentences: Commands are limited to those defined in each lexicon: `Feed` and `Wake` for animals, `Enroll`, `Advance`, `Graduate` for university. Compound actions such as `Feed Conor and wake Seamus` are not supported, neither are quantified commands such as `Feed every cat`. We assume that feeding implies no longer being hungry after and advancement only checks year of study and not examination results.
- We do not give explanations on why a sentence is True or False. 

We will keep these in mind for future interesting directions to expand the project.

# AI Usage 
- We used AI for help with small Haskell syntax issues and conceptual questions, as well as for rephrasing and formatting when writing the README.
- In terms of code, we asked AI to identify existing Haskell functions with the functionality we needed in 2 situations, which led us to `sequence` and `mapM_`. We reviewed how both functions work before using them.
- We also used AI to identify edge test cases and broaden our test coverage.
- During testing, we noticed a VS Code startup message was read as the first semantic result, shifting subsequent results. We asked AI to help diagnose this unexpected output and learned to use `setEnv "PYTHONSTARTUP" ""` to avoid this issue.