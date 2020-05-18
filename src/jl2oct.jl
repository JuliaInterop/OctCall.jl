# conversion of Julia objects in to Octave copies

function jl2oct(x::AbstractMatrix{<:Real})
    o = @cxxnew Matrix(size(x,1), size(x,2))
    p = @cxx o -> fortran_vec()
    GC.@preserve o for i = 1:length(x)
        unsafe_store!(p, x[i], i)
    end
    return o
end
