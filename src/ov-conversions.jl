# conversions between Julia types and octave_value (used by the interpreter)

# default is to go through jl2oct, but pointers need to be dereferenced
_octave_value(x) = icxx"octave_value o($x); o;"
_octave_value(x::Cxx.CxxCore.CppPtr) = icxx"octave_value o(*$x); o;"
octave_value(x) = _octave_value(jl2oct(x))

# Octave has a bool matrix but no bool vector, but since
# octave_value loses the distinction between vectors and 1-column matrices
# we might as well convert bool vectors to the latter:
octave_value(x::AbstractVector{Bool}) =
    octave_value(copyto!(Matrix{Bool}(undef, length(x),1), x))

function julia_value(o::cxxt"octave_value")
    if @cxx o -> is_scalar_type()
        if @cxx o -> iscomplex()
            return oct2jl(@cxx(o -> is_double_type()) ? @cxx(o -> complex_value()) : @cxx(o -> float_complex_value()))
        elseif @cxx o -> isfloat()
            return @cxx(o -> is_double_type()) ? @cxx(o -> double_value()) : @cxx(o -> float_value())
        elseif @cxx o -> isinteger()
            # currently unused since octave_value converts integer scalars to double by default?
            if @cxx o -> is_int16_type()
                return Int16(@cxx o -> int16_scalar_value())
            elseif @cxx o -> is_int32_type()
                return Int32(@cxx o -> int32_scalar_value())
            elseif @cxx o -> is_int64_type()
                return Int64(@cxx o -> int64_scalar_value())
            elseif @cxx o -> is_uint16_type()
                return UInt16(@cxx o -> uint16_scalar_value())
            elseif @cxx o -> is_uint32_type()
                return UInt32(@cxx o -> uint32_scalar_value())
            elseif @cxx o -> is_uint64_type()
                return UInt64(@cxx o -> uint64_scalar_value())
            # elseif @cxx o -> is_int8_type()
            #    return Int8(@cxx o -> int8_scalar_value())
            # elseif @cxx o -> is_uint8_type()
            #    return UInt8(@cxx o -> uint8_scalar_value())
            end
        elseif @cxx o -> is_bool_scalar()
            return @cxx o -> bool_value()
        end
    elseif @cxx o -> is_string()
        return oct2jl(@cxx o -> string_value())
    elseif @cxx o -> is_matrix_type()
        if @cxx o -> iscomplex()
            return oct2jl(@cxx(o -> is_double_type()) ? @cxx(o -> complex_matrix_value()) : @cxx(o -> float_complex_matrix_value()))
        elseif @cxx o -> isfloat()
            return oct2jl(@cxx(o -> is_double_type()) ? @cxx(o -> matrix_value()) : @cxx(o -> float_matrix_value()))
        elseif @cxx o -> islogical()
            return oct2jl(@cxx o -> bool_matrix_value())
        end
    elseif @cxx o -> is_range()
        return oct2jl(@cxx o -> range_value())
    end
    error("unknown octave_value type")
end