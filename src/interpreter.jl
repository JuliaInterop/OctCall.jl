# Julia interface to octave interpreter

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