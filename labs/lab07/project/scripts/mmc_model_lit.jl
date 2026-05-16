# # Модель M/M/c - полная версия с сохранением всех графиков

using DrWatson
@quickactivate "project"
using ConcurrentSim, Distributions, ResumableFunctions, StableRNGs
using DataFrames, CSV, Plots, StatsBase

# ----- Функция одного прогона -----
function run_mmc(;
    num_customers = 200,
    num_servers = 2,
    lambda = 0.9,
    mu = 0.5,
    seed = 123,
    verbose = true
)
    rng = StableRNG(seed)
    arrival_dist = Exponential(1/lambda)
    service_dist = Exponential(1/mu)

    sim = Simulation()
    servers = Resource(sim, num_servers)

    arrivals = Float64[]
    enter_service = Float64[]
    exits = Float64[]

    @resumable function customer(env::Environment, id::Int)
        @yield timeout(env, rand(rng, arrival_dist))
        push!(arrivals, now(env))
        @yield request(servers)
        push!(enter_service, now(env))
        @yield timeout(env, rand(rng, service_dist))
        @yield release(servers)
        push!(exits, now(env))
    end

    for i in 1:num_customers
        @process customer(sim, i)
    end

    run(sim)

    wait_times = enter_service .- arrivals
    service_times = exits .- enter_service
    system_times = exits .- arrivals

    mean_wait = mean(wait_times)
    mean_service = mean(service_times)
    mean_system = mean(system_times)
    rho = lambda / (num_servers * mu)

    if verbose
        println("=== M/M/$num_servers ===")
        println("Загрузка ρ = $(round(rho, digits=3))")
        println("Среднее время ожидания: $(round(mean_wait, digits=3))")
        println("Среднее время обслуживания: $(round(mean_service, digits=3))")
        println("Среднее время в системе: $(round(mean_system, digits=3))")
    end

    df = DataFrame(id=1:num_customers, arrival=arrivals, enter_service=enter_service,
                   exit=exits, wait=wait_times, service=service_times, system=system_times)
    return df, (mean_wait=mean_wait, mean_service=mean_service, mean_system=mean_system, rho=rho)
end

# ----- Базовый прогон и графики -----
function baseline_mmc()
    df, stats = run_mmc(num_customers=300, num_servers=2, lambda=0.9, mu=0.5, seed=42)
    mkpath(datadir("mmc"))
    CSV.write(datadir("mmc", "baseline.csv"), df)
    @save datadir("mmc", "baseline_stats.jld2") stats

    # График 1: время ожидания по порядку прибытия
    p1 = scatter(df.arrival, df.wait, label="wait time", xlabel="Arrival time", 
                 ylabel="Time", title="M/M/2: waiting times", markersize=3)
    savefig(plotsdir("mmc_wait_scatter.png"))

    # График 2: гистограмма времени ожидания
    p2 = histogram(df.wait, bins=20, label="", xlabel="Wait time", ylabel="Frequency",
                   title="Distribution of waiting times", color=:lightblue)
    savefig(plotsdir("mmc_wait_hist.png"))

    # График 3: время прибытия vs время выхода
    p3 = plot(df.arrival, df.exit, seriestype=:scatter, label="exit", 
              xlabel="Arrival time", ylabel="Time", title="Arrival vs Exit")
    plot!(df.arrival, df.arrival, label="arrival", linestyle=:dash)
    savefig(plotsdir("mmc_arrival_exit.png"))

    println("✅ Базовые графики M/M/c сохранены в plots/")
end

# ----- Параметрическое исследование -----
function parametric_mmc()
    servers_range = [1,2,3,4]
    lambda_range = 0.4:0.2:1.2
    mu = 0.5
    replicates = 3

    results = []
    for c in servers_range
        for λ in lambda_range
            ρ = λ / (c * mu)
            ρ ≥ 1 && continue
            for rep in 1:replicates
                df, stats = run_mmc(num_customers=500, num_servers=c, lambda=λ, 
                                    mu=mu, seed=rep+1000*c, verbose=false)
                push!(results, (c=c, λ=λ, ρ=ρ, rep=rep,
                                mean_wait=stats.mean_wait,
                                mean_system=stats.mean_system))
            end
        end
    end

    df_res = DataFrame(results)
    CSV.write(datadir("mmc_parametric.csv"), df_res)

    # График 4: зависимость времени ожидания от загрузки
    grp = combine(groupby(df_res, [:c, :ρ]), :mean_wait => mean => :avg_wait)
    p = plot(grp.ρ, grp.avg_wait, group=grp.c, xlabel="ρ (load)", ylabel="Mean wait time",
             title="M/M/c: effect of load and servers", markershape=:auto, linewidth=2,
             legendtitle="servers")
    savefig(plotsdir("mmc_param_wait.png"))

    # График 5: фиксированная загрузка ρ≈0.6
    filtered = filter(row -> abs(row.ρ - 0.6) < 0.05, df_res)
    if !isempty(filtered)
        grp2 = combine(groupby(filtered, :c), :mean_wait => mean => :avg_wait)
        p2 = bar(grp2.c, grp2.avg_wait, xlabel="Number of servers", ylabel="Mean wait time",
                 title="M/M/c at ρ≈0.6", legend=false)
        savefig(plotsdir("mmc_fixed_rho.png"))
    end
    println("✅ Параметрические графики M/M/c сохранены в plots/")
end

# ----- Запуск -----
println("="^60)
println("Задание 7.1.5: Модель M/M/c")
println("="^60)

baseline_mmc()
parametric_mmc()

println("\n✅ M/M/c выполнено. Результаты в data/ и plots/")
