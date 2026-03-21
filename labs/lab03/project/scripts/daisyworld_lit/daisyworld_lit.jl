using DrWatson
using Agents
using CairoMakie
using Plots

include(joinpath(@__DIR__, "..", "src", "daisyworld.jl"))

daisycolor(a::Daisy) = a.breed

plotkwargs = (
    agent_color = daisycolor,
    agent_size = 20,
    agent_marker = '✿',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),),
)

model = daisyworld()

plt1, _ = abmplot(model; plotkwargs...)

step!(model, 5)
plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

step!(model, 35)  # итого 40
plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

plots_dir = joinpath(@__DIR__, "..", "plots")
mkpath(plots_dir)

save(joinpath(plots_dir, "daisy_step001.png"), plt1)
save(joinpath(plots_dir, "daisy_step005.png"), plt2)
save(joinpath(plots_dir, "daisy_step040.png"), plt3)

println("Графики сохранены в $plots_dir")
