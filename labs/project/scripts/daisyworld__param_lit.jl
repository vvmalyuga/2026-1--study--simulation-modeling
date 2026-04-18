# # Параметрическое исследование: базовая визуализация
#
# Исследуем влияние максимального возраста (`max_age`) и начальной доли белых
# маргариток (`init_white`) на визуальную картину модели.

using DrWatson
using Agents
using CairoMakie
using DataFrames

include(joinpath(@__DIR__, "..", "src", "daisyworld.jl"))

# ## Параметры эксперимента
param_dict = Dict(
    :griddims => (30, 30),
    :max_age => [25, 40],
    :init_white => [0.2, 0.8],
    :init_black => 0.2,
    :albedo_white => 0.75,
    :albedo_black => 0.25,
    :surface_albedo => 0.4,
    :solar_change => 0.005,
    :solar_luminosity => 1.0,
    :scenario => :default,
    :seed => 165,
)

# Генерируем все комбинации
params_list = dict_list(param_dict)

plots_dir = joinpath(@__DIR__, "..", "plots")
mkpath(plots_dir)

for params in params_list
    model = daisyworld(; params...)

    daisycolor(a::Daisy) = a.breed

    plotkwargs = (
        agent_color = daisycolor,
        agent_size = 20,
        agent_marker = '✿',
        heatarray = :temperature,
        heatkwargs = (colorrange = (-20, 60),),
    )

    # Шаг 0
    plt1, _ = abmplot(model; plotkwargs...)
    # Шаг 5
    step!(model, 5)
    plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)
    # Шаг 40
    step!(model, 35)
    plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

    # Формируем имена файлов с параметрами
    prefix = savename("daisyworld", params)
    save(joinpath(plots_dir, prefix * "_step01.png"), plt1)
    save(joinpath(plots_dir, prefix * "_step05.png"), plt2)
    save(joinpath(plots_dir, prefix * "_step40.png"), plt3)
end

println("Все параметрические кадры сохранены в $plots_dir")
