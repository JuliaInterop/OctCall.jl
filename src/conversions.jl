# conversion of Octave objects to/from Julia copies, using the core Octave
# types (rather than octave_value types used by the interpreter)

# fallback is no conversion, so that we
# can call these functions unconditionally
jl2oct(x) = x
oct2jl(o) = o

# not done automatically by Cxx: Cxx.jl#470
jl2oct(x::Complex{Float64}) = icxx"std::complex<double>($(real(x)),$(imag(x)));"
jl2oct(x::Complex{Float32}) = icxx"std::complex<float>($(real(x)),$(imag(x)));"
oct2jl(o::Union{cxxt"std::complex<double>",cxxt"std::complex<float>"}) = Complex(@cxx(o -> real()), @cxx(o -> imag()))

jl2oct(x::AbstractString) = convert(Cxx.CxxStd.StdString, x)
oct2jl(o::Union{Cxx.CxxStd.StdString,Cxx.CxxStd.StdStringR}) = convert(String, o)

# copy data between Julia and Octave arrays, with no checking
function _unsafe_copy!(o::Union{Cxx.CxxCore.CppPtr,Cxx.CxxCore.CppValue}, x::AbstractArray{T}) where {T}
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
function _unsafe_copy!(x::AbstractArray{T}, o::Union{Cxx.CxxCore.CppPtr,Cxx.CxxCore.CppValue}) where {T}
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

# CppPtr{CxxQualType{X},CVR} to CppPtr{CppValue{CxxQualType{X}},CVR}
cppvaluetype(::Type{Cxx.CxxCore.CppPtr{T,CVR}}) where {T,CVR} = Union{Cxx.CxxCore.CppValue{T},Cxx.CxxCore.CppPtr{T,CVR},Cxx.CxxCore.CppPtr{Cxx.CxxCore.CppValue{T},CVR}}

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

            oct2jl(o::cppvaluetype(@cxxt_str($("$O1 *")))) =
                return _unsafe_copy!(Vector{$J}(undef, octsize(o)[1]), o)
        end
     end
     if O2 !== nothing
        @eval begin
            jl2oct(x::AbstractMatrix{$J}) =
                _unsafe_copy!(@cxxnew($O2(size(x,1), size(x,2))), x)

            oct2jl(o::cppvaluetype(@cxxt_str($("$O2 *"))))  =
                return _unsafe_copy!(Matrix{$J}(undef, octsize(o)...), o)
        end
    end
 end