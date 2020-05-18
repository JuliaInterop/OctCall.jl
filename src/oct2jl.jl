# conversion of Octave objects into Julia copies

# alias for Cxx class T
const OctType{T} = Cxx.CxxCore.CppPtr{<:Cxx.CxxCore.CppValue{<:Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{T}}}}

function oct2jl(o::OctType{:Matrix})
    d = @cxx o -> dims() # dim_vector
    GC.@preserve d begin
        m, n = unsafe_load(@cxx d -> elem(0)), unsafe_load(@cxx d -> elem(1))
    end
    x = Matrix{Float64}(undef, m, n)
    p = @cxx o -> fortran_vec()
    GC.@preserve o for i = 1:length(x)
        x[i] = unsafe_load(p, i)
    end
    return x
end
