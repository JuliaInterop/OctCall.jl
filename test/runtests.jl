using OctCall, Test, Random

Random.seed!(314159);

# matrix conversions
for T in (Float32,Float64,ComplexF32,ComplexF64,Bool)
    x = rand(T, 3,4)
    @test oct2jl(jl2oct(x)) == x
end
