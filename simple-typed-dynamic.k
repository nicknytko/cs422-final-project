module SIMPLE-TYPED-DYNAMIC-SYNTAX
  imports DOMAINS-SYNTAX
  imports ARRAY
  imports FLOAT-SYNTAX
  syntax Id ::= "main" [token]
  syntax Type ::= "void" | "int" | "bool" | "string" | "float"
                | Type "[" "]"
                | "Vector"
                | "Vector" "<" Type ">"      [strict, avoid]
                | "Matrix"
                | "Matrix" "<" Type ">"      [strict, avoid]
                | "(" Type ")"               [bracket]
                > Types "->" Type
  syntax Types ::= List{Type,","}
  syntax Param ::= Type Id
  syntax Params ::= List{Param,","}

  syntax MatVecBuiltInFctn ::= "ones" "(" Exps ")"              [strict]
                             | "ones" "(" Exps "," Type ")"     [strict, avoid] /* with type definition */
                             | "ones_like" "(" Exp ")"          [strict]
                             | "zeros" "(" Exps ")"             [strict]
                             | "zeros" "(" Exps "," Type ")"    [strict, avoid] /* with type definition */
                             | "zeros_like" "(" Exp ")"         [strict]
                             | "eye" "(" Exp ")"                [strict]
                             | "rows" "(" Exp ")"               [strict]
                             | "cols" "(" Exp ")"               [strict]
                             | "sin" "(" Exp ")"                [strict]
                             | "cos" "(" Exp ")"                [strict]
                             | "tan" "(" Exp ")"                [strict]
                             | "ln"  "(" Exp ")"                [strict]
                             | "exp" "(" Exp ")"                [strict]
                             | "range" "(" Exps ")"             [strict]
                             | "linspace" "(" Exps ")"          [strict]
                             | "sum" "(" Exp ")"                [strict]

  syntax Stmt ::= Type Exps ";"
                | Type Id "(" Params ")" Block
  syntax Exp ::= Int | Bool | String | Float | Id
               | "(" Exp ")"             [bracket]
               | "{=" Stmt "=}"
               | "++" Exp
               | "(" Type ")" Exp        [strict(2)] /* Cast */
               > Exp "[" Exps "]"        [strict]
               | Val "[" Exps "]"        [strict]
               > Exp "(" Exps ")"        [strict]
               | "-" Exp                 [strict]
               | "sizeOf" "(" Exp ")"    [strict]
               | "read" "(" ")"
               | MatVecBuiltInFctn
               | Exp "^T"                [strict]       /* Transpose */
               > left:
                 Exp "*" Exp             [strict, left]
               | Exp "^" Exp             [strict, left] /* Exponentiation */
               | Exp "(*)" Exp           [strict, left] /* Hadamard product */
               | Exp "/" Exp             [strict, left]
               | Exp "%" Exp             [strict, left]
               > left:
                 Exp "+" Exp             [strict, left]
               | Exp "-" Exp             [strict, left]
               > non-assoc:
                 Exp "<" Exp             [strict, non-assoc]
               | Exp "<=" Exp            [strict, non-assoc]
               | Exp ">" Exp             [strict, non-assoc]
               | Exp ">=" Exp            [strict, non-assoc]
               | Exp "==" Exp            [strict, non-assoc]
               | Exp "!=" Exp            [strict, non-assoc]
               > "!" Exp                 [strict]
               > left:
                 Exp "&&" Exp            [strict(1), left]
               | Exp "||" Exp            [strict(1), left]
               > "spawn" Block
               > Exp "=" Exp             [strict(2), right]
  syntax Exps ::= List{Exp,","}          [strict]
  syntax Val
  syntax Vals ::= List{Val,","}
  syntax Block ::= "{" "}"
                | "{" Stmt "}"

  syntax Stmt ::= "freeze" /* debug */
                | Block
                | Exp ";"                               [strict]
                | "if" "(" Exp ")" Block "else" Block   [avoid, strict(1)]
                | "if" "(" Exp ")" Block
                | "while" "(" Exp ")" Block
                | "for" "(" Stmt Exp ";" Exp ")" Block
                | "print" "(" Exps ")" ";"              [strict]
                | "println" "(" Exps ")" ";"            [strict]
                | "return" Exp ";"                      [strict]
                | "return" ";"
                | "output" Exp ";"
                | "try" Block "catch" "(" Param ")" Block
                | "throw" Exp ";"                       [strict]
                | "join" Exp ";"                        [strict]
                | "acquire" Exp ";"                     [strict]
                | "release" Exp ";"                     [strict]
                | "rendezvous" Exp ";"                  [strict]

  syntax Stmt ::= Stmt Stmt                          [right]
  rule if (E) S => if (E) S else {}                                     [macro]
  rule for(Start Cond; Step) {S:Stmt} => {Start while(Cond){S Step;}}   [macro]
  rule for(Start Cond; Step) {} => {Start while(Cond){Step;}}           [macro]
  rule T:Type E1:Exp, E2:Exp, Es:Exps; => T E1; T E2, Es;               [macro-rec]
  rule T:Type X:Id = E; => T X; X = E;                                  [macro]
  rule println(Es:Exps); => print(Es); print("\n");                     [macro]

  /* If no type is specified, assume float vector/matrix */
  rule Vector => Vector<float>    [macro]
  rule Matrix => Matrix<float>    [macro]

endmodule


module SIMPLE-TYPED-DYNAMIC
  imports SIMPLE-TYPED-DYNAMIC-SYNTAX
  imports DOMAINS
  imports FLOAT-SYNTAX
  imports FLOAT
  syntax Val ::= Int | Bool | String | Float
               | array(Type,Int,Int)
               | vector(Type,Int,Int) /* type, length, memory location */
               | matrix(Type,Int,Int,Int) /* type, rows, cols, memory location */
               | lambda(Type,Params,Stmt)
  syntax Exp ::= Val
  syntax Exps ::= Vals
  syntax KResult ::= Val
                   | Vals  // TODO: should not need this
  // the syntax declarations below are required because the sorts are
  // referenced directly by a production and, because of the way KIL to KORE
  // is implemented, the configuration syntax is not available yet
  // should simply work once KIL is removed completely
  // check other definitions for this hack as well

  syntax ControlCell
  syntax ControlCellFragment

  configuration <T color="red">
                  <threads color="orange">
                    <thread multiplicity="*" color="yellow">
                      <k color="green"> ($PGM:Stmt ~> execute) </k>
//                      <br/>
                      <control color="cyan">
                        <fstack color="blue"> .List </fstack>
                        <xstack color="purple"> .List </xstack>
                        <returnType color="LimeGreen"> void </returnType>
                       </control>
//                      <br/>
                      <env color="violet"> .Map </env>
                      <envStack> .List </envStack>
                      <holds color="black"> .Map </holds>
                      <id color="pink"> 0 </id>
                    </thread>
                  </threads>
//                  <br/>
                  <genv color="pink"> .Map </genv>
                  <store color="white"> .Map </store>
                  <busy color="cyan">.Set</busy>
                  <terminated color="red"> .Set </terminated>
                  <input color="magenta" stream="stdin"> .List </input>
                  <output color="brown" stream="stdout"> .List </output>
                  <nextLoc color="gray"> 0 </nextLoc>
                </T>
  syntax KItem ::= undefined(Type)  [latex(\bot_{#1})]

  /* Variable declaration */
  rule <k> T:Type X:Id; => . ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> undefined(T) ...</store>
       <nextLoc> L:Int => L +Int 1 </nextLoc>

  /* Array declaration */
  rule <k> T:Type X:Id[N:Int]; => . ...</k>
       <env> Env => Env[X <- L] </env>
       <store>... .Map => L |-> array(T, L +Int 1, N)
                          (L +Int 1)...(L +Int N) |-> undefined(T) ...</store>
       <nextLoc> L:Int => L +Int 1 +Int N </nextLoc>
    when N >=Int 0

  /* Matrix/vector built-ins */
  syntax Exp ::= makevec(Int,Val,Type)
  rule <k> makevec(N:Int, D:Val, T:Type) => vector(T, N, L) ... </k>
       <store> ... .Map => L ... (L +Int N -Int 1) |-> D ... </store>
       <nextLoc> L:Int => L +Int N </nextLoc>
  when N >Int 0

  syntax Exp ::= makemat(Int,Int,Val,Type)
  rule <k> makemat(M:Int, N:Int, D:Val, T:Type) => matrix(T, M, N, L) ... </k>
       <store> ... .Map => L ... (L +Int (M *Int N) -Int 1) |-> D ... </store>
       <nextLoc> L:Int => L +Int (M *Int N) </nextLoc>
  when M >Int 0 andBool N >Int 0

  /* ones */
  rule ones(N:Int) => makevec(N, 1.0, float)
  rule ones(N:Int, float) => makevec(N, 1.0, float)
  rule ones(N:Int, bool) => makevec(N, true, bool)
  rule ones(N:Int, int) => makevec(N, 1, int)

  rule ones(M:Int, N:Int) => makemat(M, N, 1.0, float)
  rule ones(N:Int, float) => makevec(N, 1.0, float)
  rule ones(N:Int, bool) => makevec(N, true, bool)
  rule ones(N:Int, int) => makevec(N, 1, int)

  rule ones_like(vector(float, N:Int, _:Int)) => makevec(N, 1.0, float)
  rule ones_like(vector(bool, N:Int, _:Int)) => makevec(N, true, bool)
  rule ones_like(vector(int, N:Int, _:Int)) => makevec(N, 1, int)
  rule ones_like(matrix(float, M:Int, N:Int, _:Int)) => makemat(M, N, 1.0, float)
  rule ones_like(matrix(bool, M:Int, N:Int, _:Int)) => makemat(M, N, true, bool)
  rule ones_like(matrix(int, M:Int, N:Int, _:Int)) => makemat(M, N, 1, int)

  /* zeros */
  rule zeros(N:Int) => makevec(N, 0.0, float)
  rule zeros(N:Int, float) => makevec(N, 0.0, float)
  rule zeros(N:Int, bool) => makevec(N, false, bool)
  rule zeros(N:Int, int) => makevec(N, 0, int)

  rule zeros(M:Int, N:Int) => makemat(M, N, 0.0, float)
  rule zeros(M:Int, N:Int, float) => makemat(M, N, 0.0, float)
  rule zeros(M:Int, N:Int, bool) => makemat(M, N, 0.0, bool)
  rule zeros(M:Int, N:Int, int) => makemat(M, N, 0.0, int)

  rule zeros_like(vector(float, N:Int, _:Int)) => makevec(N, 0.0, float)
  rule zeros_like(vector(bool, N:Int, _:Int)) => makevec(N, false, bool)
  rule zeros_like(vector(int, N:Int, _:Int)) => makevec(N, 0, int)
  rule zeros_like(matrix(float, M:Int, N:Int, _:Int)) => makemat(M, N, 0.0, float)
  rule zeros_like(matrix(bool, M:Int, N:Int, _:Int)) => makemat(M, N, false, bool)
  rule zeros_like(matrix(int, M:Int, N:Int, _:Int)) => makemat(M, N, 0, int)

  /* eye */
  syntax Id ::= "$m" | "$i"
  rule <k> eye(N:Int) => {=
           Matrix $m = zeros(N,N);
           for (int $i = 0; $i < N; ++$i) {
               $m[$i,$i] = 1.0;
           }
           output $m;
       =} ... </k> [structural]

  /* range */
  rule range(N:Int) => {=
      Vector $m = zeros(N);
      for (int $i = 1; $i < N; ++$i) {
          $m[$i] = $i;
      }
      output $m;
  =}
  rule range(Low:Int, High:Int) => {=
      Vector $m = zeros(High - Low);
      for (int $i = 0; $i < (High - Low); ++$i) {
          $m[$i] = $i + Low;
      }
      output $m;
  =}
  /* linspace */
  rule linspace(Low:Val, High:Val, N:Int) => {=
      Vector $m = zeros(N);
      float $j = (float) Low;
      float $k = (float) High;
      for (int $i = 0; $i < N; ++$i) {
          $m[$i] = $j + (($k-$j)/(N -Int 1))*$i;
      }
      output $m;
  =}

  context _:Type _::Exp[HOLE::Exps];

  /* Nested array definition */
  syntax Id ::= "$1" | "$2"
  rule T:Type X:Id[N1:Int, N2:Int, Vs:Vals];
    => T[]<Vs> X[N1];
       {
         T[][]<Vs> $1=X;
         for(int $2=0; $2 <= N1 - 1; ++$2) {
           T X[N2,Vs];
           $1[$2] = X;
         }
       }
    [structural]

  /* Function declaration */
  rule <k> T:Type F:Id(Ps:Params) S => . ...</k>
       <env> Env => Env[F <- L] </env>
       <store>... .Map => L |-> lambda(T, Ps, S) ...</store>
       <nextLoc> L => L +Int 1 </nextLoc>
  syntax KItem ::= "execute"
  rule <k> execute => main(.Exps); </k>
       <env> Env </env>
       <genv> .Map => Env </genv>  [structural]
  rule <k> X:Id => V ...</k>
       <env>... X |-> L ...</env>
       <store>... L |-> V:Val ...</store>  [lookup]
  context ++(HOLE => lvalue(HOLE))
  rule <k> ++loc(L) => I +Int 1 ...</k>
       <store>... L |-> (I:Int => I +Int 1) ...</store>  [increment]

  /* Trivial arithmetic operators */
  /* Perform automatic up-casting from integers to floating point */
  syntax Id ::= "$i" | "$j" | "$k" | "$z"

  rule I1 + I2 => I1 +Int I2
  rule Str1 + Str2 => Str1 +String Str2
  rule F1 + F2 => F1 +Float F2
  rule I1:Int + F2:Float => Int2Float(I1, 53, 11) +Float F2
  rule F1:Float + I2:Int => F1 +Float Int2Float(I2, 53, 11)

  /* Mat + mat */
  rule <k> matrix(T, M, N, I) + matrix(T, M, N, J) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T,M,N,I)[$i,$j] + matrix(T,M,N,J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]

  rule <k> matrix(T, M, N, I) - matrix(T, M, N, J) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T,M,N,I)[$i,$j] - matrix(T,M,N,J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]

  /* vec + vec */
  rule <k> vector(T, N, I) + vector(T, N, J) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T,N,I)[$i] + vector(T,N,J)[$i];
           }
           output $z;
       =} ... </k> [structural]
  rule <k> vector(T, N, I) - vector(T, N, J) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T,N,I)[$i] - vector(T,N,J)[$i];
           }
           output $z;
       =} ... </k> [structural]

  rule I1:Int   - I2:Int => I1 -Int I2
  rule F1:Float - F2:Float => F1 -Float F2
  rule F1:Float - I2:Int => F1 -Float Int2Float(I2,53,11)
  rule I1:Int   - F2:Float => Int2Float(I1,53,11) -Float F2

  rule I1:Int   * I2:Int => I1 *Int I2
  rule F1:Float * F2:Float => F1 *Float F2
  rule F1:Float * I2:Int => F1 *Float Int2Float(I2,53,11)
  rule I1:Int   * F2:Float => Int2Float(I1,53,11) *Float F2

  rule I1:Int   / I2:Int   => I1 /Int I2 when I2 =/=K 0
  rule F1:Float / F2:Float => F1 /Float F2 when F2 =/=Float 0.0
  rule F1:Float / I2:Int   => F1 /Float Int2Float(I2,53,11) when I2 =/=K 0
  rule I1:Int   / F2:Float => Int2Float(I1,53,11) /Float F2 when F2 =/=Float 0.0

  /* Mat-mat */
  rule <k> matrix(T, M, N, I) * matrix(T, N, O, J) => {=
           Matrix $z = zeros(M, O);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < O; ++$j) {
                   for (int $k = 0; $k < N; ++$k) {
                       $z[$i,$j] = $z[$i,$j] + matrix(T,M,N,I)[$i,$k] * matrix(T,N,O,J)[$k,$j];
                   }
               }
           }
           output $z;
       =} ... </k> [structural]

  /* Mat (*) Mat */
  rule <k> matrix(T, M, N, I) (*) matrix(T, M, N, J) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T,M,N,I)[$i,$j] * matrix(T,M,N,J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]

  /* Mat * constant */
  rule <k> matrix(T, M, N, I) * Z:Val => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T,M,N,I)[$i,$j] * Z;
               }
           }
           output $z;
       =} ... </k> when typeOf(Z) ==K float orBool typeOf(Z) ==K int [structural]
  rule <k> Z:Val * matrix(T, M, N, I) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T,M,N,I)[$i,$j] * Z;
               }
           }
           output $z;
       =} ... </k> when typeOf(Z) ==K float orBool typeOf(Z) ==K int [structural]

  /* Mat negation */
    rule <k> -matrix(T, M, N, I) => {=
           Matrix $z = zeros(M, N, T);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = -matrix(T,M,N,I)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]

  /* Mat transpose */
    rule <k> matrix(T, M, N, I)^T => {=
           Matrix $z = zeros(N, M, T);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T,M,N,I)[$j,$i];
               }
           }
           output $z;
       =} ... </k> [structural]

  /* Mat-vec y=Ax */
  rule <k> matrix(T, M, N, I) * vector(T, N, J) => {=
           Vector $z = zeros(M);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i] = $z[$i] + (matrix(T, M, N, I)[$i,$j] * vector(T, N, J)[$j]);
               }
           }
           output $z;
       =} ... </k> [structural]

  /* Vec-mat y^T=x^T A <=> y=A^T x */
  rule <k> vector(T, N, J) * matrix(T, N, M, I) => {=
           Vector $z = zeros(M);
           for (int $i = 0; $i < N; ++$i) {
               for (int $j = 0; $j < M; ++$j) {
                   $z[$i] = $z[$i] + (matrix(T, M, N, I)[$j,$i] * vector(T, N, J)[$j]);
               }
           }
           output $z;
       =} ... </k> [structural]

  /* Vec-vec dot product */
  rule <k> vector(T, N, I) * vector(T, N, J) => {=
           float $z = 0.0;
           for (int $i = 0; $i < N; ++$i) {
               $z = $z + (vector(T, N, I)[$i] * vector(T, N, J)[$i]);
           }
           output $z;
       =} ... </k> [structural]

  /* Vec (*) vec hadamard product */
  rule <k> vector(T, N, I) (*) vector(T, N, J) => {=
           float $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] * vector(T, N, J)[$i];
           }
           output $z;
       =} ... </k> [structural]

  /* Vec-constant multiply */
  rule <k> vector(T, N, I) * V:Val => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] * V;
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int  [structural]
  rule <k> V:Val * vector(T, N, I) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] * V;
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int [structural]

  /* Vec-constant divide */
  rule <k> vector(T, N, I) / V:Val => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] / V;
           }
           output $z;
       =} ... </k> [structural]
  rule <k> V:Val / vector(T, N, I) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = V / vector(T, N, I)[$i];
           }
           output $z;
       =} ... </k> [structural]


  /* Vec-constant add, subtract */
  rule <k> vector(T, N, I) + V:Val => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] + V;
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int [structural]
  rule <k> V:Val + vector(T, N, I) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] + V;
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int [structural]
  rule <k> vector(T, N, I) - V:Val => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] - V;
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int [structural]
  rule <k> V:Val - vector(T, N, I) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = V - vector(T, N, I)[$i];
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int [structural]

  /* Negation */
  rule <k> -vector(T, N, I) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = -vector(T, N, I)[$i];
           }
           output $z;
       =} ... </k> [structural]

  /* Entrywise operators */
  /* Sine */
  rule sin(F:Float) => sinFloat(F)
  rule <k> sin(vector(T, N, I)) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = sin(vector(T, N, I)[$i]);
           }
           output $z;
       =} ... </k> [structural]
  rule <k> sin(matrix(T, M, N, I)) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = sin(matrix(T,M,N,I)[$i,$j]);
               }
           }
           output $z;
       =} ... </k> [structural]
  /* Cosine */
  rule cos(F:Float) => cosFloat(F)
  rule <k> cos(vector(T, N, I)) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = cos(vector(T, N, I)[$i]);
           }
           output $z;
       =} ... </k> [structural]
  rule <k> cos(matrix(T, M, N, I)) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = cos(matrix(T, M,N,I)[$i,$j]);
               }
           }
           output $z;
       =} ... </k> [structural]
  /* Tangent */
  rule tan(F:Float) => tanFloat(F)
  rule <k> tan(vector(T, N, I)) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = tan(vector(T, N, I)[$i]);
           }
           output $z;
       =} ... </k> [structural]
  rule <k> tan(matrix(T, M, N, I)) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = tan(matrix(T,M,N,I)[$i,$j]);
               }
           }
           output $z;
       =} ... </k> [structural]
  /* Natural log */
  rule ln(F:Float) => logFloat(F)
  rule <k> ln(vector(T, N, I)) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = ln(vector(T, N, I)[$i]);
           }
           output $z;
       =} ... </k> [structural]
  rule <k> ln(matrix(T, M, N, I)) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = ln(matrix(T,M,N,I)[$i,$j]);
               }
           }
           output $z;
       =} ... </k> [structural]
  /* Exponential function */
  rule exp(F:Float) => expFloat(F)
  rule <k> ln(vector(T, N, I)) => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = exp(vector(T, N, I)[$i]);
           }
           output $z;
       =} ... </k> [structural]
  rule <k> ln(matrix(T, M, N, I)) => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = exp(matrix(T,M,N,I)[$i,$j]);
               }
           }
           output $z;
       =} ... </k> [structural]
  /* Exponentiation */
  rule I1:Int   ^ I2:Int   => I1 ^Int I2
  rule I1:Int   ^ F2:Float => expFloat(F2 *Float logFloat(Int2Float(I1, 53, 11)))
  rule F1:Float ^ F2:Float => expFloat(F2 *Float logFloat(F1))
  rule F1:Float ^ I2:Int   => expFloat(Int2Float(I2, 53, 11) *Float logFloat(F1))
  rule <k> vector(T, N, I) ^ V:Val => {=
           Vector $z = zeros(N);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T, N, I)[$i] ^ V;
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int [structural]
  rule <k> matrix(T, M, N, I) ^ V:Val => {=
           Matrix $z = zeros(M, N);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T,M,N,I)[$i,$j] ^ V;
               }
           }
           output $z;
       =} ... </k> when typeOf(V) ==K float orBool typeOf(V) ==K int [structural]

  rule I1 % I2 => I1 %Int I2 when I2 =/=K 0

  rule - I => 0 -Int I
  rule - F => 0.0 -Float F

  rule I1 < I2 => I1 <Int I2
  rule F1 < F2 => F1 <Float F2
  rule F1 < I2 => F1 <Float Int2Float(I2, 53, 11)
  rule I1 < F2 => Int2Float(I1, 53, 11) <Float F2

  rule I1 <= I2 => I1 <=Int I2
  rule F1 <= F2 => F1 <=Float F2
  rule F1 <= I2 => F1 <=Float Int2Float(I2, 53, 11)
  rule I1 <= F2 => Int2Float(I1, 53, 11) <=Float F2

  rule I1 > I2 => I1 >Int I2
  rule F1 > F2 => F1 >Float F2
  rule F1 > I2 => F1 >Float Int2Float(I2, 53, 11)
  rule I1 > F2 => Int2Float(I1, 53, 11) >Float F2

  rule I1 >= I2 => I1 >=Int I2
  rule F1 >= F2 => F1 >=Float F2
  rule F1 >= I2 => F1 >=Float Int2Float(I2, 53, 11)
  rule I1 >= F2 => Int2Float(I1, 53, 11) >=Float F2

  rule V1:Val == V2:Val => V1 ==K V2
  rule V1:Val != V2:Val => V1 =/=K V2
  rule ! T => notBool(T)
  rule true  && E => E
  rule false && _ => false
  rule true  || _ => true
  rule false || E => E
  rule array(T:Type,L:Int,M:Int)[N1:Int, N2:Int, Vs:Vals] => array(T,L,M)[N1][N2, Vs]
    [structural, anywhere]

  /* Vector comparisons */
  rule <k> vector(T1, N, I) < vector(T2, N, J) => {=
           Vector<bool> $z;
           $z = zeros(N, bool);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T1, N, I)[$i] < vector(T2, N, J)[$i];
           }
           output $z;
       =} ... </k> [structural]
  rule <k> vector(T1, N, I) <= vector(T2, N, J) => {=
           Vector<bool> $z;
           $z = zeros(N, bool);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T1, N, I)[$i] <= vector(T2, N, J)[$i];
           }
           output $z;
       =} ... </k> [structural]
  rule <k> vector(T1, N, I) > vector(T2, N, J) => {=
           Vector<bool> $z;
           $z = zeros(N, bool);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T1, N, I)[$i] > vector(T2, N, J)[$i];
           }
           output $z;
       =} ... </k> [structural]
  rule <k> vector(T1, N, I) >= vector(T2, N, J) => {=
           Vector<bool> $z;
           $z = zeros(N, bool);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T1, N, I)[$i] <= vector(T2, N, J)[$i];
           }
           output $z;
       =} ... </k> [structural]
  rule <k> vector(T1, N, I) == vector(T2, N, J) => {=
           Vector<bool> $z;
           $z = zeros(N, bool);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T1, N, I)[$i] == vector(T2, N, J)[$i];
           }
           output $z;
       =} ... </k> [structural]
  rule <k> vector(T1, N, I) != vector(T2, N, J) => {=
           Vector<bool> $z;
           $z = zeros(N, bool);
           for (int $i = 0; $i < N; ++$i) {
               $z[$i] = vector(T1, N, I)[$i] != vector(T2, N, J)[$i];
           }
           output $z;
       =} ... </k> [structural]

  /* Matrix comparisons */
  rule <k> matrix(T1, M, N, I) < matrix(T2, M, N, J) => {=
           Matrix<bool> $z = zeros(M, N, bool);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T1, M, N, I)[$i,$j] < matrix(T2, M, N, J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]
  rule <k> matrix(T1, M, N, I) <= matrix(T2, M, N, J) => {=
           Matrix<bool> $z = zeros(M, N, bool);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T1, M, N, I)[$i,$j] <= matrix(T2, M, N, J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]
  rule <k> matrix(T1, M, N, I) > matrix(T2, M, N, J) => {=
           Matrix<bool> $z = zeros(M, N, bool);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T1, M, N, I)[$i,$j] > matrix(T2, M, N, J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]
  rule <k> matrix(T1, M, N, I) >= matrix(T2, M, N, J) => {=
           Matrix<bool> $z = zeros(M, N, bool);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T1, M, N, I)[$i,$j] >= matrix(T2, M, N, J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]
  rule <k> matrix(T1, M, N, I) == matrix(T2, M, N, J) => {=
           Matrix<bool> $z = zeros(M, N, bool);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T1, M, N, I)[$i,$j] == matrix(T2, M, N, J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]
  rule <k> matrix(T1, M, N, I) != matrix(T2, M, N, J) => {=
           Matrix<bool> $z = zeros(M, N, bool);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z[$i,$j] = matrix(T1, M, N, I)[$i,$j] != matrix(T2, M, N, J)[$i,$j];
               }
           }
           output $z;
       =} ... </k> [structural]

  /* vector summation */
  rule <k> sum(vector(float, N, I)) => {=
           float $z = 0;
           for (int $i = 0; $i < N; ++$i) {
               $z = $z + vector(float, N, I)[$i];
           }
           output $z;
        =} ... </k> [structural]
  rule <k> sum(vector(bool, N, I)) => {=
           int $z = 0;
           for (int $i = 0; $i < N; ++$i) {
               if (vector(bool, N, I)[$i]) {
                   $z = $z + 1;
               }
           }
           output $z;
        =} ... </k> [structural]
  rule <k> sum(vector(int, N, I)) => {=
           int $z = 0;
           for (int $i = 0; $i < N; ++$i) {
               $z = $z + vector(int, N, I)[$i];
           }
           output $z;
        =} ... </k> [structural]

  /* matrix summation */
  rule <k> sum(matrix(float, M, N, I)) => {=
           float $z = 0;
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z = $z + matrix(float, N, N, I)[$i];
               }
           }
           output $z;
        =} ... </k> [structural]
  rule <k> sum(matrix(bool, M, N, I)) => {=
           int $z = 0;
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   if (matrix(bool, N, N, I)[$i]) {
                       $z = $z + 1;
                   }
               }
           }
           output $z;
        =} ... </k> [structural]
  rule <k> sum(matrix(int, M, N, I)) => {=
           int $z = 0;
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   $z = $z + matrix(int, N, N, I)[$i];
               }
           }
           output $z;
        =} ... </k> [structural]

  /* Casting */
  rule (float) I:Int => Int2Float(I, 53, 11)
  rule (int) F:Float => Float2Int(F)
  rule (int) true => 1
  rule (int) false => 0
  rule (float) true => 1.0
  rule (float) false => 0.0
  rule (bool) F:Float => (F >Float 0.0)
  rule (bool) I:Int => (I >Int 0)
  rule (T) V:Val => V when typeOf(V) ==K T /* Skip cast to self */
  rule <k> (Vector<T1>) vector(T2, N, I) => {=
           Vector<T1> $z = zeros(N, T1);
           for (int $i = 0; $i < N; ++$i) {
               T2 $k = vector(T2, N, I)[$i];
               $z[$i] = (T1) $k;
           }
           output $z;
       =} ... </k> [structural]
  rule <k> (Matrix<T1>) matrix(T2, M, N, I) => {=
           Matrix<T1> $z = zeros(N, T1);
           for (int $i = 0; $i < M; ++$i) {
               for (int $j = 0; $j < N; ++$j) {
                   T2 $k = matrix(T2, M, N, I)[$i,$j];
                   $z[$i,$j] = (T1) $k;
               }
           }
           output $z;
       =} ... </k> [structural]

  /* Array access */
  rule array(_:Type, L:Int, M:Int)[N:Int] => lookup(L +Int N)
    when N >=Int 0 andBool N <Int M  [structural, anywhere]
  rule sizeOf(array(_,_,N)) => N

  /* Matrix/Vector access */
  rule vector(_, N:Int, L:Int)[I:Int] => lookup(L +Int I)
    when I >=Int 0 andBool I <Int N  [structural, anywhere]
  rule sizeOf(vector(_, N:Int, _)) => N
  rule rows(vector(_, N:Int, _)) => N /* Assume automatic row/col vector as in numpy */
  rule cols(vector(_, N:Int, _)) => N

  rule matrix(_, M:Int, N:Int, L:Int)[I:Int, J:Int] => lookup(L +Int J +Int (I *Int N))
    when I >=Int 0 andBool I <Int M andBool I >=Int 0 andBool I <Int N  [structural, anywhere]
  rule sizeOf(matrix(_, M:Int, N:Int, _)) => M *Int N
  rule rows(matrix(_, M:Int, _, _)) => M
  rule cols(matrix(_, _, N:Int, _)) => N

  syntax KItem ::= (Type,Map,K,ControlCellFragment)

  /* Function declaration */
  rule <k> lambda(T,Ps,S)(Vs:Vals) ~> K => mkDecls(Ps,Vs) S return; </k>
       <control>
         <fstack> .List => ListItem((T',Env,K,C)) ...</fstack>
         <returnType> T' => T </returnType>
         C
       </control>
       <env> Env => GEnv </env>
       <genv> GEnv </genv>

  /* Function return */
  rule <k> return V:Val; ~> _ => V ~> K </k>
       <control>
         <fstack> ListItem((T',Env,K,C)) => .List ...</fstack>
         <returnType> T => T' </returnType>
         (_ => C)
       </control>
       <env> _ => Env </env>
    when typeOf(V) ==K T   // check the type of the returned value
  syntax Val ::= nothing(Type)
  rule <k> return; => return nothing(T); ...</k> <returnType> T </returnType>
    [structural]
  rule <k> read() => I ...</k> <input> ListItem(I:Int) => .List ...</input>  [read]
  context (HOLE => lvalue(HOLE)) = _

  /* Variable Assignment */
  rule <k> loc(L) = V:Val => V ...</k> <store>... L |-> (V' => V) ...</store>
    when typeOf(V) ==K typeOf(V')  [assignment]
  /* Up-casting int to float */
  rule <k> loc(L) = V:Int => V ...</k> <store>... L |-> (V' => Int2Float(V, 53, 11)) ...</store>
    when typeOf(V') ==K float [assignment]

  /* Blocks */
  rule {} => .  [structural]
  rule <k> { S } => S ~> setEnv(Env) ...</k>  <env> Env </env>  [structural]

  syntax Exp ::= exec(Stmt)
  syntax Exp ::= execExp(Exp) [strict]

  rule <k> exec(output V:Val;) => V ... </k>
       <env> _ => Env </env>
       <envStack> ListItem(Env) => .List ... </envStack>
  rule <k> exec(output E:Exp;) => execExp(E) ... </k>
  rule <k> execExp(V:Val) => V ... </k>
       <env> _ => Env </env>
       <envStack> ListItem(Env) => .List ... </envStack>
  rule <k> exec(S1:Stmt S2:Stmt) => S1 ~> exec(S2) ... </k>

  rule <k> {= S =} => exec(S) ... </k>
       <env> Env </env>
       <envStack> .List => ListItem(Env) ... </envStack>

  rule S1:Stmt S2:Stmt => S1 ~> S2  [structural]
  rule _:Val; => .
  rule if ( true) S else _ => S
  rule if (false) _ else S => S
  rule while (E) S => if (E) {S while(E)S}  [structural]

  /* Print statements */
  rule <k> print(V:Val, Es => Es); ...</k> <output>... .List => ListItem(V) </output>
    when typeOf(V) ==K int orBool typeOf(V) ==K string  [print]
  rule <k> print(V:Float, Es => Es); ... </k>
       <output> ... .List => ListItem(Float2String(V)) </output> [print]
  rule <k> print(true, Es => Es); ... </k>
       <output> ... .List => ListItem("True") </output> [print]
  rule <k> print(false, Es => Es); ... </k>
       <output> ... .List => ListItem("False") </output> [print]
  rule <k> print(.Vals); => . ... </k>

  /* Print vector */
  rule print(vector(_, N:Int, I:Int), Es); => {
           print("[ ");
           for(int $1=0; $1 < N -Int 1; ++$1){
               print(lookup($1 + I), ", ");
           }
           print(lookup(I +Int N -Int 1), " ]");
       } print(Es);       [structural]

  rule print(matrix(_, M:Int, N:Int, I:Int), Es); => {
           print("[ ");
           for (int $1=0; $1 < M; ++$1) {
               if ($1 != 0) {
                   print("  ");
               }
               for (int $2=0; $2 < N -Int 1; ++$2) {
                   print(lookup($2 + $1 * N + I), ", ");
               }
               print(lookup(M - 1 + $1 * N + I));
               if ($1 < M -Int 1) {
                   print("\n");
               }
           }
           print(" ]");
       } print(Es);       [structural]


  syntax KItem ::= (Param,Stmt,K,Map,ControlCellFragment)  // Param instead of Id

  syntax KItem ::= "popx"

  /* Try-Catch */
  rule <k> (try S1 catch(P) S2 => S1 ~> popx) ~> K </k>
       <control>
         <xstack> .List => ListItem((P, S2, K, Env, C)) ...</xstack>
         C
       </control>
       <env> Env </env>

  /* Stack pop */
  rule <k> popx => . ...</k>
       <xstack> ListItem(_) => .List ...</xstack>

  /* Exception throw */
  rule <k> throw V:Val; ~> _ => { T X = V; S2 } ~> K </k>
       <control>
         <xstack> ListItem((T:Type X:Id, S2, K, Env, C)) => .List ...</xstack>
         (_ => C)
       </control>
       <env> _ => Env </env>

   /* Thread spawning */
   rule <thread>...
          <k> spawn S => !T:Int ...</k>
          <env> Env </env>
        ...</thread>
        (.Bag => <thread>...
                <k> S </k>
                <env> Env </env>
                <id> !T </id>
              ...</thread>)
   rule (<thread>... <k>.</k> <holds>H</holds> <id>T</id> ...</thread> => .Bag)
        <busy> Busy => Busy -Set keys(H) </busy>
        <terminated>... .Set => SetItem(T) ...</terminated>
   rule <k> join T:Int; => . ...</k>
        <terminated>... SetItem(T) ...</terminated>
   rule <k> acquire V:Val; => . ...</k>
        <holds>... .Map => V |-> 0 ...</holds>
        <busy> Busy (.Set => SetItem(V)) </busy>
     when (notBool(V in Busy:Set))  [acquire]

   rule <k> acquire V; => . ...</k>
        <holds>... V:Val |-> (N:Int => N +Int 1) ...</holds>
   rule <k> release V:Val; => . ...</k>
        <holds>... V |-> (N => N:Int -Int 1) ...</holds>
      when N >Int 0

   rule <k> release V; => . ...</k> <holds>... V:Val |-> 0 => .Map ...</holds>
        <busy>... SetItem(V) => .Set ...</busy>
   rule <k> rendezvous V:Val; => . ...</k>
        <k> rendezvous V; => . ...</k>  [rendezvous]
  syntax Stmt ::= mkDecls(Params,Vals)  [function]
  rule mkDecls((T:Type X:Id, Ps:Params), (V:Val, Vs:Vals))
    => T X=V; mkDecls(Ps,Vs)
  rule mkDecls(.Params,.Vals) => {}
  syntax Exp ::= lookup(Exp) [strict]  // see NOTES.md for why Exp instead of KItem
  rule <k> lookup(L:Int) => V ...</k> <store>... L |-> V:Val ...</store>  [lookup]

  syntax KItem ::= setEnv(Map)
  rule <k> setEnv(Env) => . ...</k>  <env> _ => Env </env>  [structural]
  rule (setEnv(_) => .) ~> setEnv(_)  [structural]
  syntax Exp ::= lvalue(K)
  syntax Val ::= loc(Int)

  /* Variable lookup */
  rule <k> lvalue(X:Id => loc(L)) ...</k>  <env>... X |-> L:Int ...</env>
    [structural]

  //context lvalue(_[HOLE])
  //context lvalue(HOLE[_])
  context lvalue(_::Exp[HOLE::Exps])
  context lvalue(HOLE::Exp[_::Exps])

  rule lvalue(lookup(L:Int) => loc(L))  [structural]
  syntax Type ::= Type "<" Vals ">"  [function]
  rule T:Type<_,Vs:Vals> => T[]<Vs>
  rule T:Type<.Vals> => T
  syntax Map ::= Int "..." Int "|->" K
    [function, latex({#1}\ldots{#2}\mapsto{#3})]
  rule N...M |-> _ => .Map  when N >Int M
  rule N...M |-> K => N |-> K (N +Int 1)...M |-> K  when N <=Int M

// Type of a value.
  syntax Type ::= typeOf(K)  [function]
  rule typeOf(_:Int) => int
  rule typeOf(_:Float) => float
  rule typeOf(_:Bool) => bool
  rule typeOf(_:String) => string
  /* I have no idea why I have to specify float/bool/int instead of just a generic T:Type.
     But I was getting inner parser errors, so here it is! */
  rule typeOf(vector(float,_,_)) => Vector<float>
  rule typeOf(vector(bool,_,_)) => Vector<bool>
  rule typeOf(vector(int,_,_)) => Vector<int>
  rule typeOf(matrix(float,_,_,_)) => Matrix<float>
  rule typeOf(matrix(bool,_,_,_)) => Matrix<bool>
  rule typeOf(matrix(int,_,_,_)) => Matrix<int>

  rule typeOf(array(T,_,_)) => (T[])   // () needed! K parses [] as "no tags"
  rule typeOf(lambda(T,Ps,_)) => getTypes(Ps) -> T
  rule typeOf(undefined(T)) => T
  rule typeOf(nothing(T)) => T
  syntax Types ::= getTypes(Params)  [function]
  rule getTypes(T:Type _:Id) => T, .Types   // I would like to not use .Types
  rule getTypes(T:Type _:Id, P, Ps) => T, getTypes(P,Ps)
  rule getTypes(.Params) => void, .Types
endmodule
