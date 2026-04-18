using DrWatson
using Agents
using DataFrames
using CairoMakie

script_dir = @__DIR__
src_dir = joinpath(script_dir, "..", "src")
plots_dir = joinpath(script_dir, "..", "plots")
mkpath(plots_dir)

include(joinpath(src_dir, "daisyworld.jl"))

black(a) = a.breed == :black
white(a) = a.breed == :white
adata = [(black, count), (white, count)]

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
    agent_df, model_df = run!(model, 1000; adata)

    figure = Figure(size = (600, 400))
    ax = figure[1, 1] = Axis(figure, xlabel = "tick", ylabel = "daisy count")
    blackl = lines!(ax, agent_df[!, :time], agent_df[!, :count_black], color = :black)
    whitel = lines!(ax, agent_df[!, :time], agent_df[!, :count_white], color = :orange)
    Legend(figure[1, 2], [blackl, whitel], ["black", "white"], labelsize = 12)

    name = "daisy-count_maxage=$(params[:max_age])_initwhite=$(params[:init_white])"
    save(joinpath(plots_dir, "$(name).png"), figure)
end
