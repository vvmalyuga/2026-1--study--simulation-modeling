using DrWatson
using Agents
using CairoMakie

script_dir = @__DIR__
src_dir = joinpath(script_dir, "..", "src")
plots_dir = joinpath(script_dir, "..", "plots")
mkpath(plots_dir)

include(joinpath(src_dir, "daisyworld.jl"))

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

params_list = dict_list(param_dict)

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
    plt1, _ = abmplot(model; plotkwargs...)
    step!(model, 5)
    plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)
    step!(model, 40)
    plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

    # Формируем имена файлов на основе параметров
    name = "daisyworld_maxage=$(params[:max_age])_initwhite=$(params[:init_white])"
    save(joinpath(plots_dir, "$(name)_step001.png"), plt1)
    save(joinpath(plots_dir, "$(name)_step005.png"), plt2)
    save(joinpath(plots_dir, "$(name)_step040.png"), plt3)
end
