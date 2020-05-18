# conversion of Octave objects to/from Julia copies

# alias for Cxx class T
const OctType{T} = Cxx.CxxCore.CppPtr{<:Cxx.CxxCore.CppValue{<:Cxx.CxxCore.CxxQualType{Cxx.CxxCore.CppBaseType{T}}}}

for (J,O) in
    ((Float64,:Matrix),
     (Float32,:FloatMatrix),
     (ComplexF64,:ComplexMatrix),
     (ComplexF32,:FloatComplexMatrix),
     (Bool,:boolMatrix))
     @eval begin
         function jl2oct(x::AbstractMatrix{$J})
             o = @cxxnew $O(size(x,1), size(x,2))
             p = @cxx o -> fortran_vec()
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
             p = @cxx o -> fortran_vec()
             GC.@preserve o for i = 1:length(x)
                 x[i] = unsafe_load(p, i)
             end
             return x
         end
     end
 end