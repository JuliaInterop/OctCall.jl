# OctCall: Calling GNU Octave from Julia

This package allows you to call and interact with [GNU Octave](https://www.gnu.org/software/octave/), a mostly *Matlab-compatible* free-software numerical-computing language, from Julia.   It works by directly accessing the GNU Octave C++ libraries using [Cxx.jl](https://github.com/JuliaInterop/Cxx.jl), and hence should have performance comparable to calling Octave functions from within Octave.

Currently, communication of basic types such as numeric/boolean scalars, matrices/vectors, and strings are supported.  Support for more types will be added in the future.

At this stage, OctCall is a pre-release preview.