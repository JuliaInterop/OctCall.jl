# conversion of Octave objects to/from Julia copies

# alias for Cxx class T
const OctType{T} = Cxx.CxxCore.CppPtr{<:Cxx.CxxCore.CppValue{<:Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{T}}}}

# aliases for std::complex<double> and std::complex<float>:
const cxxComplexF64 = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::complex")},Tuple{Float64}},(false, false, false)},16}
const cxxComplexF32 = Cxx.CxxCore.CppValue{Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppTemplate{Cxx.CxxCore.CppBaseType{Symbol("std::__1::complex")},Tuple{Float32}},(false, false, false)},8}

# fallback is no conversion, so that we
# can call these functions unconditionally
jl2oct(x) = x
oct2jl(o) = o

# not done automatically by Cxx: Cxx.jl#470
jl2oct(x::Complex{Float64}) = icxx"std::complex<double>($(real(x)),$(imag(x)));"
jl2oct(x::Complex{Float32}) = icxx"std::complex<float>($(real(x)),$(imag(x)));"
oct2jl(o::Union{cxxComplexF64,cxxComplexF32}) = Complex(@cxx(o -> real()), @cxx(o -> imag()))

for (J,O) in
    ((Float64,:Matrix),
     (Float32,:FloatMatrix),
     (ComplexF64,:ComplexMatrix),
     (ComplexF32,:FloatComplexMatrix),
     (Bool,:boolMatrix))
     @eval begin
         function jl2oct(x::AbstractMatrix{$J})
             o = @cxxnew $O(size(x,1), size(x,2))
             po = @cxx o -> fortran_vec()
             # the Julia types above have the same binary
             # layout as the corresponding C++ types, so
             # converting to an explicit Julia pointer is
             # safe and simplifies conversions
             p = Ptr{$J}(convert(Ptr{Cvoid}, po))
             GC.@preserve o for i = 1:length(x)
                 unsafe_store!(p, x[i], i)
             end
             return o
         end

         function oct2jl(o::OctType{$(QuoteNode(O))})
             d = @cxx o -> dims() # dim_vector
             GC.@preserve d begin
                 m, n = unsafe_load(@cxx d -> elem(0)), unsafe_load(@cxx d -> elem(1))
             end
             x = Matrix{$J}(undef, m, n)
             po = @cxx o -> fortran_vec()
             p = Ptr{$J}(convert(Ptr{Cvoid}, po))
             GC.@preserve o for i = 1:length(x)
                 x[i] = unsafe_load(p, i)
             end
             return x
         end
     end
 end