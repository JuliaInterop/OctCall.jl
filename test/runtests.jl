using OctCall, Test, Random

Random.seed!(314159);

≅(x,y::T) where {T} = x == y && x isa T
roundtripeqT(x) = oct2jl(jl2oct(x)) ≅ x
ovroundtrip(x) = OctCall.julia_value(OctCall.octave_value(x))
ovroundtripeqT(x) = ovroundtrip(x) ≅ x
ovroundtripeq(x) = ovroundtrip(x) == x

@testset "core Octave types" begin
    # vector conversions
    for T in (Float32,Float64,ComplexF32,ComplexF64)
        @test roundtripeqT(rand(T, 3))
    end

    # matrix conversions
    for T in (Float32,Float64,ComplexF32,ComplexF64,Bool)
        @test roundtripeqT(rand(T, 3,4))
    end

    @test roundtripeqT(1:0.1:10)
    @test roundtripeqT(1:2:9)
    @test roundtripeqT(1:10)

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

    # vector and matrix conversions (vectors get converted to 1-column matrices)
    for T in (Float32,Float64,ComplexF32,ComplexF64,Bool)
        @test ovroundtripeqT(rand(T, 3,4))

        x = rand(T, 3)
        x2 = ovroundtrip(x)
        @test x2 isa Array{T,2} && size(x2,2) == 1
        @test vec(x2) == x
    end

    @test ovroundtripeqT(true) && ovroundtripeqT(false)

    @test ovroundtripeqT("Hello world!")

    @test ovroundtripeqT(1:0.1:10)
    @test ovroundtripeqT(1:2:9)
    @test ovroundtripeqT(1:10)
end

