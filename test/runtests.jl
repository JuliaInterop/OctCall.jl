using OctCall, Test, Random

Random.seed!(314159);

roundtripeq(x) = oct2jl(jl2oct(x)) == x

# vector conversions
for T in (Float32,Float64,ComplexF32,ComplexF64)
    @test roundtripeq(rand(T, 3))
end

# matrix conversions
for T in (Float32,Float64,ComplexF32,ComplexF64,Bool)
    @test roundtripeq(rand(T, 3,4))
end

@test roundtripeq("Hello world!")
