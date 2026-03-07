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

function sir_model!(du, u, p, t)
    S, I, R = u
    β, γ = p
    N = S + I + R
    du[1] = -β * I * S / N
    du[2] = β * I * S / N - γ * I
    du[3] = γ * I
end

base_params = Dict(
    :S0 => 990.0,           # начальное число восприимчивых
    :I0 => 10.0,            # начальное число зараженных
    :R0 => 0.0,             # начальное число выздоровевших
    :β => 0.4,              # коэффициент заражения
    :γ => 0.1,              # коэффициент выздоровления
    :tspan => (0.0, 100.0), # интервал времени
    :solver => Tsit5(),     # метод решения
    :saveat => 1.0,         # шаг сохранения
    :experiment_name => "base_experiment"
)

println("Базовые параметры эксперимента:")
for (key, value) in base_params
    println("  $key = $value")
end

function run_sir_experiment(params::Dict)
    @unpack S0, I0, R0, β, γ, tspan, solver, saveat = params
    u0 = [S0, I0, R0]
    p = [β, γ]

    prob = ODEProblem(sir_model!, u0, tspan, p)
    sol = solve(prob, solver; saveat=saveat)

    df = DataFrame(t=sol.t, S=[u[1] for u in sol.u],
                   I=[u[2] for u in sol.u], R=[u[3] for u in sol.u])

    peak_idx = argmax(df.I)
    peak_time = df.t[peak_idx]
    peak_value = df.I[peak_idx]
    total_recovered = df.R[end]
    R0_value = β / γ

    return Dict(
        "solution" => sol,
        "df" => df,
        "peak_time" => peak_time,
        "peak_value" => peak_value,
        "total_recovered" => total_recovered,
        "R0" => R0_value,
        "parameters" => params
    )
end

data, path = produce_or_load(
    datadir(script_name, "single"),
    base_params,
    run_sir_experiment,
    prefix = "sir",
    verbose = true
)

println("\nРезультаты базового эксперимента:")
println("  Пик эпидемии: ", round(data["peak_value"], digits=1))
println("  Время пика: ", round(data["peak_time"], digits=1), " дней")
println("  Всего переболело: ", round(data["total_recovered"], digits=1))
println("  R₀ = ", round(data["R0"], digits=2))
println("  Файл результатов: ", path)

p1 = plot(data["df"].t, data["df"].I,
    label="I(t)",
    xlabel="Время, дни",
    ylabel="Число зараженных",
    title="Модель SIR (β=$(base_params[:β]), γ=$(base_params[:γ]))",
    lw=2,
    color=:red,
    legend=:topright,
    grid=true
)

vline!(p1, [data["peak_time"]], color=:black, linestyle=:dash, label="пик")
savefig(plotsdir(script_name, "single_experiment.png"))

param_grid = Dict(
    :S0 => [[990.0]],
    :I0 => [[10.0]],
    :R0 => [[0.0]],
    :β => [0.2, 0.3, 0.4, 0.5, 0.6],  # исследуемые β
    :γ => [0.05, 0.1, 0.15, 0.2],      # исследуемые γ
    :tspan => [(0.0, 100.0)],
    :solver => [Tsit5()],
    :saveat => [1.0],
    :experiment_name => ["parametric_scan"]
)

all_params = dict_list(param_grid)

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ СКАНИРОВАНИЕ SIR")
println("Всего комбинаций: ", length(all_params))
println("Исследуемые β: ", param_grid[:β])
println("Исследуемые γ: ", param_grid[:γ])
println("="^60)

all_results = []
all_dfs = []

for (i, params) in enumerate(all_params)
    println("Прогресс: $i/$(length(all_params)) | β=$(params[:β]), γ=$(params[:γ])")

    data, path = produce_or_load(
        datadir(script_name, "parametric_scan"),
        params,
        run_sir_experiment,
        prefix = "scan",
        verbose = false
    )

    result_summary = merge(
        params,
        Dict(
            :peak_time => data["peak_time"],
            :peak_value => data["peak_value"],
            :total_recovered => data["total_recovered"],
            :R0 => data["R0"],
            :filepath => path
        )
    )
    push!(all_results, result_summary)

    df = data["df"]
    df[!, :β] = fill(params[:β], nrow(df))
    df[!, :γ] = fill(params[:γ], nrow(df))
    push!(all_dfs, df)
end

results_df = DataFrame(all_results)
println("\nСводная таблица результатов:")
println(results_df[!, [:β, :γ, :peak_value, :total_recovered, :R0]])

CSV.write(datadir(script_name, "summary.csv"), results_df)
@save datadir(script_name, "all_results.jld2") results_df

p2 = plot(size=(800, 500), xlabel="Время, дни", ylabel="Число зараженных",
    title="Влияние β на динамику (γ=0.1)", legend=:topright)

γ_fixed = 0.1
for β_val in [0.2, 0.3, 0.4, 0.5, 0.6]
    params = Dict(:β => β_val, :γ => γ_fixed, :S0 => 990.0, :I0 => 10.0,
                  :R0 => 0.0, :tspan => (0.0, 100.0), :solver => Tsit5(), :saveat => 1.0)
    data, _ = produce_or_load(datadir(script_name, "parametric_scan"), params,
                               run_sir_experiment, prefix="scan", verbose=false)
    plot!(p2, data["df"].t, data["df"].I, label="β=$β_val", lw=2)
end
savefig(plotsdir(script_name, "comparison_beta.png"))

p3 = plot(size=(800, 500), xlabel="Время, дни", ylabel="Число зараженных",
    title="Влияние γ на динамику (β=0.4)", legend=:topright)

β_fixed = 0.4
for γ_val in [0.05, 0.1, 0.15, 0.2]
    params = Dict(:β => β_fixed, :γ => γ_val, :S0 => 990.0, :I0 => 10.0,
                  :R0 => 0.0, :tspan => (0.0, 100.0), :solver => Tsit5(), :saveat => 1.0)
    data, _ = produce_or_load(datadir(script_name, "parametric_scan"), params,
                               run_sir_experiment, prefix="scan", verbose=false)
    plot!(p3, data["df"].t, data["df"].I, label="γ=$γ_val", lw=2)
end
savefig(plotsdir(script_name, "comparison_gamma.png"))

p4 = plot(results_df.β, results_df.peak_value, group=results_df.γ,
    xlabel="β", ylabel="Пиковое число зараженных",
    title="Зависимость пика от β при разных γ",
    markersize=6, markerstrokewidth=0, linewidth=2,
    legendtitle="γ", legend=:topleft)
savefig(plotsdir(script_name, "peak_vs_beta.png"))

p5 = plot(results_df.R0, results_df.total_recovered,
    seriestype=:scatter,
    label="Результаты",
    xlabel="R₀",
    ylabel="Всего переболело",
    title="Зависимость итогового числа переболевших от R₀",
    markersize=6,
    markercolor=:green,
    legend=:bottomright
)
savefig(plotsdir(script_name, "total_vs_R0.png"))

β_unique = sort(unique(results_df.β))
γ_unique = sort(unique(results_df.γ))
peak_matrix = zeros(length(γ_unique), length(β_unique))

for (i, γ_val) in enumerate(γ_unique)
    for (j, β_val) in enumerate(β_unique)
        row = filter(r -> r.β == β_val && r.γ == γ_val, results_df)
        if !isempty(row)
            peak_matrix[i, j] = row[1, :peak_value]
        end
    end
end

p6 = heatmap(β_unique, γ_unique, peak_matrix,
    xlabel="β",
    ylabel="γ",
    title="Тепловая карта: пик эпидемии",
    color=:viridis,
    colorbar_title="Макс. I"
)
savefig(plotsdir(script_name, "heatmap.png"))

@save datadir(script_name, "all_plots.jld2") p1 p2 p3 p4 p5 p6

println("\n" * "="^60)
println("ПАРАМЕТРИЧЕСКОЕ ИССЛЕДОВАНИЕ ЗАВЕРШЕНО")
println("="^60)
println("\nРезультаты сохранены в:")
println("  • data/$(script_name)/single/")
println("  • data/$(script_name)/parametric_scan/")
println("  • data/$(script_name)/all_results.jld2")
println("  • plots/$(script_name)/")
