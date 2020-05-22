# conversion of Octave objects to/from Julia copies

# alias for Cxx class T
const OctType{T} = Cxx.CxxCore.CppPtr{<:Cxx.CxxCore.CppValue{<:Cxx.CxxCore.CxxQualType{<:Cxx.CxxCore.CppBaseType{T}}}}

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

# copy data between Julia and Octave arrays, with no checking
function _unsafe_copy!(o::Cxx.CxxCore.CppPtr, x::AbstractArray{T}) where {T}
    po = @cxx o -> fortran_vec()
    # the Julia types above have the same binary
    # layout as the corresponding C++ types, so
    # converting to an explicit Julia pointer is
    # safe and simplifies conversions
    p = Ptr{T}(convert(Ptr{Cvoid}, po))
    GC.@preserve o for i = 1:length(x)
        unsafe_store!(p, x[i], i)
    end
    return o
end
function _unsafe_copy!(x::AbstractArray{T}, o::Cxx.CxxCore.CppPtr) where {T}
    po = @cxx o -> fortran_vec()
    p = Ptr{T}(convert(Ptr{Cvoid}, po))
    GC.@preserve o for i = 1:length(x)
        x[i] = unsafe_load(p, i)
    end
    return x
end

# analogue to size() for an octave array
function octsize(o)
    d = @cxx o -> dims() # dim_vector
    GC.@preserve d ntuple(i -> unsafe_load(@cxx d -> elem(i-1)), @cxx d -> ndims())
end

for (J,O1,O2) in
    ((Float64,:ColumnVector,:Matrix),
     (Float32,:FloatColumnVector,:FloatMatrix),
     (ComplexF64,:ComplexColumnVector,:ComplexMatrix),
     (ComplexF32,:FloatComplexColumnVector,:FloatComplexMatrix),
     (Bool,nothing,:boolMatrix))
     if O1 !== nothing
        @eval begin
            jl2oct(x::AbstractVector{$J}) =
                _unsafe_copy!(@cxxnew($O1(length(x))), x)

            oct2jl(o::OctType{$(QuoteNode(O1))}) =
                return _unsafe_copy!(Vector{$J}(undef, octsize(o)[1]), o)
        end
     end
     if O2 !== nothing
        @eval begin
            jl2oct(x::AbstractMatrix{$J}) =
                _unsafe_copy!(@cxxnew($O2(size(x,1), size(x,2))), x)

            oct2jl(o::OctType{$(QuoteNode(O2))}) =
                return _unsafe_copy!(Matrix{$J}(undef, octsize(o)...), o)
        end
    end
 end