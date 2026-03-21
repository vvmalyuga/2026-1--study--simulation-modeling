# # Анимация модели Daisyworld
#
# Создадим видео, показывающее эволюцию модели во времени.

using DrWatson
@quickactivate "project"
using Agents
using CairoMakie

include("../src/daisyworld.jl")

# ## Настройка анимации
daisycolor(a::Daisy) = a.breed

plotkwargs = (
    agent_color = daisycolor,
    agent_size = 20,
    agent_marker = '✿',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),),
)

# ## Создание модели и видео
model = daisyworld()

plots_dir = joinpath(@__DIR__, "..", "plots")
mkpath(plots_dir)

abmvideo(
    joinpath(plots_dir, "simulation.mp4"),
    model;
    title = "Daisy World",
    frames = 60,          # количество кадров
    plotkwargs...,
)

println("Видео сохранено в $plots_dir/simulation.mp4")
