 == CS 422 Final Project ==

I suppose some sort of introduction is in order.  In this project, I added matrices and vectors as first class
types in dynamically typed simple, as well as a healthy suite of operators and built-in functions to do operations
on these new types.  I'm not sure if this is particularly "cool" from a programming languages perspective, but I
definitely had a lot of fun implementing it (maybe too much fun, as you will see), and this was definitely interesting
to me.  Included is the new syntax/semantics in the file "simple-typed-dynamic.k" and a few realistic-ish test programs
that demo the new functionality.

- Float type -

This is a minor point, but a "float" type was added to simple since it did not already exist.  Arithmetic expressions
between integers and floats will automatically "up-scale" the datatype to float.  This is consistent with numpy and
matlab behavior.

- Vector and Matrix types -

The two new types added are Vector<T> and Matrix<T>, T being one of int, bool, or float.  Note that the type does not
contain the actual size of the vector/matrix.  I acknowledge the idea that you sent in your email, but I couldn't think
of a nice way to add that to the syntax that would play nicely with function arguments.  Oh well.

There are also the shorthand types "Vector" and "Matrix", which simply rewrite to "Vector<float>" and "Matrix<float>" by default, respectively.

- Vector and Matrix operators -

The new operators added for vector and matrix types include:

Matrix:
 M + M          (element-wise addition)
 M - M          (element-wise subtraction)
 M * M          (matrix multiplication)
 M (*) M        (hadamard product)
 M * c == c * M (matrix-constant multiplication)
 M * v == v * M (matrix-vector product)
 - M            (matrix negation)
 M ^ T          (matrix transposition)
 M ^ f          (element-wise exponentiation)
 M > M          (element-wise comparison)
 M >= M          "
 M < M           "
 M <= M          "
 M == M          "
 M != M          "

Vector:
 V + V          (element-wise addition)
 V - V          (element-wise subtraction)
 V * V          (vector dot product)
 V (*) V        (hadamard product)
 V * c == c * V (vector-constant multiplication)
 V / c == c / V (element-wise division by constant */
 V + c == c + V (element-wise addition by constant)
 V - c == c +-V (element-wise subtraction by constant)
 - V            (vector negation)
 V ^ f          (element-wise exponentiation)
 V > V          (element-wise comparison)
 V >= V          "
 V < V           "
 V <= V          "
 V == V          "
 V != V          "

The output of the comparison operators is a boolean vector/matrix that is the result
of the comparison performed on each entry.

- Built-in functions -

As you can see, I got a little bit crazy defining built-in functions.  These are heavily
inspired by numpy syntax.

 (vector/matrix creation)

ones(M:Int, [N:Int], [Type])
  - creates a matrix or vector full of 1 with the specified type.
    if no type is specified, will default to float.

ones_like(V)
  - create a matrix or vector full of 1 with the same shape and
    type as some other value V.

zeros(M:Int, [N:Int], [Type])
  - creates a matrix or vector full of 0 with the specified type.
    if no type is specified, will default to float.

zeros_like(V)
  - create a matrix or vector full of 0 with the same shape and
    type as some other value V.

eye(N:Int)
  - create an N x N identity matrix

range(M:int, [N:Int])
  - creates a vector contains each integer in the range of M (inclusive) to N (exclusive).
    if N is not specified, then this is from 0 to M.

linspace(Low, High, N:Int)
  - creates a vector containing N evenly spaced points between Low (inclusive) and High (inclusive).

 (shape helpers)

rows(V)
  - return the number of rows in a matrix.  for a vector, just returns the number of entries.

cols(V)
  - return the number of rows in a matrix.  for a vector, just returns the number of entries.

 (vector elementwise functions)

sin(V):
  - compute entrywise sine of a vector.  returns a new vector.

cos(V):
  - compute entrywise cosine of a vector.  returns a new vector.

sin(V):
  - compute entrywise sine of a vector.  returns a new vector.

cos(V):
  - compute entrywise cosine of a vector.  returns a new vector.

tan(V):
  - compute entrywise tangent of a vector.  returns a new vector.

tan(V):
  - compute entrywise tangent of a vector.  returns a new vector.

ln(V):
  - compute entrywise natural log of a vector.  returns a new vector.

exp(V):
  - compute entrywise e^x_i of a vector.  returns a new vector.

sum(V/M):
  - compute the summation of all elements of a vector or matrix.

- Casting -

Types can now be explicitly cast to other types with the C-style syntax of (Type) Exp;
Floats, ints, and bools can all be cast to each other, as well as the different vector
types can be cast to one another.

For casting to bool, nonzero values are assumed to be true and zero is false.  Casting from
bool just assigns 1 to true and 0 to false.

- Statement expression -

I don't know if this is the proper name for it, but as a small syntactical sugar to myself I've
added what *I call* statement expressions.  This allows executing some block of code as a expression,
extracting exactly one value from the block.  The syntax looks like:

int x = {=
    int z = 1;
    /* some sort of complicated computation here */
    output z;
    =};

/* x now has the value of z from inside the block */

This was very helpful in defining any sort of matrix or vector operation as expressions can now
be rewritten to blocks of code that are executed.

- Conclusion -

I hope that I included everything that I added above -- though I probably missed at least one thing.  I
really enjoyed working on this and while I wouldn't consider myself a "programming languages" person now,
I definitely have some new-found appreciation for it.

Some things I would've added if I had some more time:
- A way to explicitly define vectors or matrices.  For example:
  Vector v = [0.0, 1.0, 2.0, 3.0];
- Defining the shape of a vector/matrix as part of the type.
- Full parity between vector and matrix functions.  There are quite a few
  vector element-wise functions that do not have their equivalent for matrices.

== Test programs ==

Here is a small overview of the test programs I have included.

- casting.simple -
Demonstrates casting between different primitive and vector data types.

- comparison.simple -
Shows elementwise comparison of two vectors and how they result in a
boolean vector.  Also as a neat hidden feature, sum(V) can be used to
count how many true elements are in a boolean vector.

- lotka-volterra.simple -
Integration of the Lotka-Volterra predator prey equations using
an RK4 explicit integrator.  This shows how one may effortlessly write
complicated code using the built-in operators.

- poisson.simple -
Solution to the Poisson problem in 1D.  Sets up a matrix and right hand side and
solves it using conjugate gradients.

- quadrature.simple -
Uses the composite trapezoidal rule to compute a few integrals.

- transpose.simple -
Miscellaneous demo of matrix transposition, hadamard product, and mat-mat multiplication.

- vector.simple -
Very simple program showing how vectors may be printed and added.
