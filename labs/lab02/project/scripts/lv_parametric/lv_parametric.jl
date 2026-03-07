using DrWatson
@quickactivate "project"

using DifferentialEquations
using DataFrames
using Plots
using StatsPlots
using LaTeXStrings
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

function lotka_volterra!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p
    du[1] = α*x - β*x*y
    du[2] = δ*x*y - γ*y
end

base_params = Dict(
    :x0 => 40.0,            # начальное число жертв
    :y0 => 9.0,             # начальное число хищников
    :α => 0.1,              # рождаемость жертв
    :β => 0.02,             # поедание жертв
    :δ => 0.01,             # конверсия в хищников
    :γ => 0.3,              # смертность хищников
    :tspan => (0.0, 200.0), # интервал времени
    :solver => Tsit5(),     # метод решения
    :saveat => 0.5,         # шаг сохранения
    :experiment_name => "base_experiment"
)

println("Базовые параметры эксперимента:")
for (key, value) in base_params
    println("  $key = $value")
end

function run_lv_experiment(params::Dict)
    @unpack x0, y0, α, β, δ, γ, tspan, solver, saveat = params
    u0 = [x0, y0]
    p = [α, β, δ, γ]

    prob = ODEProblem(lotka_volterra!, u0, tspan, p)
    sol = solve(prob, solver; saveat=saveat, reltol=1e-8, abstol=1e-10)

    df = DataFrame(t=sol.t, prey=[u[1] for u in sol.u],
                   predator=[u[2] for u in sol.u])

    mean_prey = mean(df.prey)
    mean_predator = mean(df.predator)
    x_star = γ / δ
    y_star = α / β

    return Dict(
        "solution" => sol,
        "df" => df,
        "mean_prey" => mean_prey,
        "mean_predator" => mean_predator,
        "x_star" => x_star,
        "y_star" => y_star,
        "parameters" => params
    )
end

data, path = produce_or_load(
    datadir(script_name, "single"),
    base_params,
    run_lv_experiment,
    prefix = "lv",
    verbose = true
)

println("\nРезультаты базового эксперимента:")
println("  Средняя численность жертв: ", round(data["mean_prey"], digits=2))
println("  Средняя численность хищников: ", round(data["mean_predator"], digits=2))
println("  Теоретическое равновесие: x*=$(round(data["x_star"], digits=2)), y*=$(round(data["y_star"], digits=2))")
println("  Файл результатов: ", path)

p1 = plot(data["df"].t, [data["df"].prey data["df"].predator],
    label=[L"Жертвы x(t)" L"Хищники y(t)"],
    xlabel="Время",
    ylabel="Численность",
    title="Модель Лотки-Вольтерры (базовый эксперимент)",
    lw=2,
    color=[:green :red],
    legend=:topright,
    grid=true
)

hline!(p1, [data["x_star"]], color=:green, linestyle=:dash, alpha=0.5, label="x*")
hline!(p1, [data["y_star"]], color=:red, linestyle=:dash, alpha=0.5, label="y*")

savefig(plotsdir(script_name, "single_experiment.png"))

param_grid = Dict(
    :x0 => [[40.0]],
    :y0 => [[9.0]],
    :α => [0.05, 0.1, 0.15, 0.2],    # исследуемые α (рождаемость жертв)
    :β => [0.02],
    :δ => [0.01],
    :γ => [0.2, 0.3, 0.4],            # исследуемые γ (смертность хищников)
    :tspan => [(0.0, 200.0)],
    :solver => [Tsit5()],
    :saveat => [0.5],
    :experiment_name => ["parametric_scan"]
)

all_params = dict_list(param_grid)

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ СКАНИРОВАНИЕ LV")
println("Всего комбинаций: ", length(all_params))
println("Исследуемые α: ", param_grid[:α])
println("Исследуемые γ: ", param_grid[:γ])
println("="^60)

all_results = []
all_dfs = []

for (i, params) in enumerate(all_params)
    println("Прогресс: $i/$(length(all_params)) | α=$(params[:α]), γ=$(params[:γ])")

    data, path = produce_or_load(
        datadir(script_name, "parametric_scan"),
        params,
        run_lv_experiment,
        prefix = "scan",
        verbose = false
    )

    result_summary = merge(
        params,
        Dict(
            :mean_prey => data["mean_prey"],
            :mean_predator => data["mean_predator"],
            :x_star => data["x_star"],
            :y_star => data["y_star"],
            :filepath => path
        )
    )
    push!(all_results, result_summary)

    df = data["df"]
    df[!, :α] = fill(params[:α], nrow(df))
    df[!, :γ] = fill(params[:γ], nrow(df))
    push!(all_dfs, df)
end

results_df = DataFrame(all_results)
println("\nСводная таблица результатов:")
println(results_df[!, [:α, :γ, :mean_prey, :mean_predator, :x_star, :y_star]])

CSV.write(datadir(script_name, "summary.csv"), results_df)
@save datadir(script_name, "all_results.jld2") results_df

p2 = plot(size=(900, 500), xlabel="Время", ylabel="Численность жертв",
    title="Влияние α на динамику жертв (γ=0.3)", legend=:topright)

γ_fixed = 0.3
for α_val in [0.05, 0.1, 0.15, 0.2]
    params = Dict(:α => α_val, :γ => γ_fixed, :β => 0.02, :δ => 0.01,
                  :x0 => 40.0, :y0 => 9.0, :tspan => (0.0, 200.0),
                  :solver => Tsit5(), :saveat => 0.5)
    data, _ = produce_or_load(datadir(script_name, "parametric_scan"), params,
                               run_lv_experiment, prefix="scan", verbose=false)
    plot!(p2, data["df"].t, data["df"].prey, label="α=$α_val", lw=2)
end
savefig(plotsdir(script_name, "comparison_alpha.png"))

p3 = plot(size=(900, 500), xlabel="Время", ylabel="Численность хищников",
    title="Влияние γ на динамику хищников (α=0.1)", legend=:topright)

α_fixed = 0.1
for γ_val in [0.2, 0.3, 0.4]
    params = Dict(:α => α_fixed, :γ => γ_val, :β => 0.02, :δ => 0.01,
                  :x0 => 40.0, :y0 => 9.0, :tspan => (0.0, 200.0),
                  :solver => Tsit5(), :saveat => 0.5)
    data, _ = produce_or_load(datadir(script_name, "parametric_scan"), params,
                               run_lv_experiment, prefix="scan", verbose=false)
    plot!(p3, data["df"].t, data["df"].predator, label="γ=$γ_val", lw=2)
end
savefig(plotsdir(script_name, "comparison_gamma.png"))

p4 = plot(results_df.α, results_df.mean_prey, group=results_df.γ,
    xlabel="α", ylabel="Средняя численность жертв",
    title="Зависимость средней численности жертв от α",
    markersize=6, markerstrokewidth=0, linewidth=2,
    legendtitle="γ", legend=:topleft)
savefig(plotsdir(script_name, "mean_prey_vs_alpha.png"))

p5 = plot(size=(800, 600), xlabel="Жертвы", ylabel="Хищники",
    title="Фазовые портреты при разных α", legend=:topright)

for α_val in [0.05, 0.1, 0.15, 0.2]
    params = Dict(:α => α_val, :γ => 0.3, :β => 0.02, :δ => 0.01,
                  :x0 => 40.0, :y0 => 9.0, :tspan => (0.0, 200.0),
                  :solver => Tsit5(), :saveat => 0.5)
    data, _ = produce_or_load(datadir(script_name, "parametric_scan"), params,
                               run_lv_experiment, prefix="scan", verbose=false)
    plot!(p5, data["df"].prey, data["df"].predator, label="α=$α_val", lw=1.5, alpha=0.7)
end
savefig(plotsdir(script_name, "phase_portraits.png"))

@save datadir(script_name, "all_plots.jld2") p1 p2 p3 p4 p5

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ ИССЛЕДОВАНИЕ ЗАВЕРШЕНО")
println("="^60)
println("\nРезультаты сохранены в:")
println("  • data/$(script_name)/single/")
println("  • data/$(script_name)/parametric_scan/")
println("  • data/$(script_name)/all_results.jld2")
println("  • plots/$(script_name)/")
