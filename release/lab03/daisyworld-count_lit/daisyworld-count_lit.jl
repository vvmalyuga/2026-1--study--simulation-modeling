using DrWatson
using Agents
using CairoMakie
using DataFrames

include(joinpath(@__DIR__, "..", "src", "daisyworld.jl"))

black(a) = a.breed == :black
white(a) = a.breed == :white
adata = [(black, count), (white, count)]

model = daisyworld(; solar_luminosity = 1.0)
agent_df, model_df = run!(model, 1000; adata)

figure = Figure(size = (600, 400))
ax = Axis(figure[1, 1], xlabel = "tick", ylabel = "daisy count")

blackl = lines!(ax, agent_df[!, :time], agent_df[!, :count_black], color = :black)
whitel = lines!(ax, agent_df[!, :time], agent_df[!, :count_white], color = :orange)

Legend(figure[1, 2], [blackl, whitel], ["black", "white"], labelsize = 12)

plots_dir = joinpath(@__DIR__, "..", "plots")
mkpath(plots_dir)
save(joinpath(plots_dir, "daisy_count.png"), figure)

println("График численности сохранён в $plots_dir/daisy_count.png")
