# conversions between Julia types and octave_value (used by the interpreter)

# default is to go through jl2oct
octave_value(x) = icxx"octave_value o($(jl2oct(x))); o;"

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
        end
    elseif @cxx o -> is_string()
        return oct2jl(@cxx o -> string_value())
    elseif @cxx o -> is_matrix_type()
        if @cxx o -> iscomplex()
            return oct2jl(@cxx(o -> is_double_type()) ? @cxx(o -> complex_matrix_value()) : @cxx(o -> float_complex_matrix_value()))
        elseif @cxx o -> isfloat()
            return oct2jl(@cxx(o -> is_double_type()) ? @cxx(o -> matrix_value()) : @cxx(o -> float_matrix_value()))
        end
    end
    error("unknown octave_value type")
end