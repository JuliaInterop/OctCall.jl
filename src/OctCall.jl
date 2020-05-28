module OctCall

export jl2oct, oct2jl

using Cxx
import Libdl

const depfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
isfile(depfile) || error("OctCall not properly installed. Please run Pkg.build(\"IJulia\")")
include(depfile) # generated by Pkg.build("OctCall")

cxx"""
#include <complex>
"""

addHeaderDir(oct_h_dir, kind=C_User)
cxxinclude("octave/oct.h")
cxxinclude("octave/interpreter.h")

# lazy initialization of interpreter
let _interpreter = cxxt"octave::interpreter *"(C_NULL)
    global interpreter
    function interpreter()
        if reinterpret(Ptr{Cvoid}, _interpreter) == C_NULL
            _interpreter = icxx"new octave::interpreter;"
            @cxx _interpreter -> initialize_history(false)
            if 0 != @cxx _interpreter -> execute()
                error("failed to start Octave interpreter")
            end
        end
        return _interpreter
    end
end

function __init__()
    Libdl.dlopen(liboctave, Libdl.RTLD_GLOBAL)
    Libdl.dlopen(liboctinterp, Libdl.RTLD_GLOBAL)
    addHeaderDir(oct_h_dir, kind=C_User)
    cxxinclude("octave/oct.h")
    cxxinclude("octave/interpreter.h")
end

include("conversions.jl")
include("ov-conversions.jl")

end # module