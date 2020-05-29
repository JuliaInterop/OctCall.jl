using OctCall, Test, Random

Random.seed!(314159);

≅(x,y::T) where {T} = x == y && x isa T
roundtripeqT(x) = oct2jl(jl2oct(x)) ≅ x
ovroundtripeqT(x) = OctCall.julia_value(OctCall.octave_value(x)) ≅ x
ovroundtripeq(x) = OctCall.julia_value(OctCall.octave_value(x)) == x

@testset "core Octave types" begin
    # vector conversions
    for T in (Float32,Float64,ComplexF32,ComplexF64)
        @test roundtripeqT(rand(T, 3))
    end

    # matrix conversions
    for T in (Float32,Float64,ComplexF32,ComplexF64,Bool)
        @test roundtripeqT(rand(T, 3,4))
    end

    @test roundtripeqT("Hello world!")
end

@testset "octave_value conversions" begin
    # scalar octave_value conversions
    for T in (Float32,Float64,ComplexF32,ComplexF64)
        @test ovroundtripeqT(rand(T))
    end

    # integer types are converted to double by Octave
    for T in (Int16,Int32,Int64,UInt16,UInt32,UInt64)
        @test ovroundtripeq(rand(T(1):T(100)))
    end

    @test ovroundtripeqT(true) && ovroundtripeqT(false)

    @test ovroundtripeqT("Hello world!")
end
