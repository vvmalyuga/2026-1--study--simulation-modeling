using DrWatson
@quickactivate "project"
include(srcdir("daisyworld.jl"))
model = daisyworld()
println("Model created with $(length(model.agents)) agents")
