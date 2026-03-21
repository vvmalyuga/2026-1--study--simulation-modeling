using DrWatson
using Agents
using CairoMakie

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

plots_dir = joinpath(@__DIR__, "..", "plots")
mkpath(plots_dir)

abmvideo(
    joinpath(plots_dir, "simulation.webm"),
    model;
    title = "Daisy World",
    frames = 60,
    plotkwargs...,
)

println("Видео сохранено в $plots_dir/simulation.mp4")
