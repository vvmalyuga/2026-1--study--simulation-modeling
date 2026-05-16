# # Модель Росса (резервирование и ремонт)
# 
# **Цель:** Система с `N` работающими машинами, `S` запасными, `R` ремонтниками.
# Машины выходят из строя, ремонтируются, пополняют резерв. При исчерпании резерва – крах.
# 
# ## Подключение пакетов

using DrWatson
@quickactivate "project"
using ConcurrentSim, Distributions, ResumableFunctions, Random, StableRNGs
using DataFrames, CSV, Plots, Statistics

# ## Структуры параметров и результатов

Base.@kwdef mutable struct RossParams
    N::Int = 10
    S::Int = 3
    mean_time_to_fail::Float64 = 100.0
    mean_repair_time::Float64 = 1.0
    num_repairmen::Int = 1
    seed::Int = 42
end

struct RossRunResult
    crash_time::Float64
    repairman_utilization::Float64
    avg_queue_length::Float64
    operational_history::Vector{Tuple{Float64,Int}}
    queue_history::Vector{Tuple{Float64,Int}}
end

# ## Симуляция одного набора параметров

function run_ross_single(params::RossParams; verbose=true)
    rng = StableRNG(params.seed)
    env = Simulation()
    repair_queue = Resource(env, params.num_repairmen)

    stats = Dict(
        :failures => 0,
        :repairs => 0,
        :spares => params.S,
        :crash_time => Inf,
        :queue_length => Ref(0),
        :repair_start_times => Dict{Int,Float64}(),
        :repair_end_times => Dict{Int,Float64}(),
        :operational_history => Vector{Tuple{Float64,Int}}(),
        :queue_history => Vector{Tuple{Float64,Int}}()
    )

    @resumable function system_monitor(env::Environment, interval::Float64)
        while true
            @yield timeout(env, interval)
            t = now(env)
            operational = stats[:spares] + params.N
            push!(stats[:operational_history], (t, operational))
        end
    end

    @resumable function queue_monitor(env::Environment, interval::Float64)
        while true
            @yield timeout(env, interval)
            push!(stats[:queue_history], (now(env), stats[:queue_length][]))
        end
    end

    @resumable function machine(env::Environment, id::Int)
        while true
            work_time = rand(rng, Exponential(params.mean_time_to_fail))
            @yield timeout(env, work_time)
            stats[:failures] += 1

            if stats[:spares] > 0
                stats[:spares] -= 1
            else
                stats[:crash_time] = now(env)
                throw(StopSimulation("No spares at time $(now(env))"))
            end

            stats[:queue_length][] += 1
            @yield request(repair_queue)
            stats[:queue_length][] -= 1

            stats[:repair_start_times][id] = now(env)
            repair_time = rand(rng, Exponential(params.mean_repair_time))
            @yield timeout(env, repair_time)
            stats[:repair_end_times][id] = now(env)
            @yield release(repair_queue)

            stats[:spares] += 1
            stats[:repairs] += 1
        end
    end

    @process system_monitor(env, 0.5)
    @process queue_monitor(env, 0.5)

    for i in 1:params.N
        @process machine(env, i)
    end

    try
        run(env)
    catch e
        if !isa(e, StopSimulation)
            rethrow()
        end
    end

    crash_time = stats[:crash_time]
    if isinf(crash_time)
        error("Simulation did not crash – increase time or adjust parameters")
    end

    total_busy = 0.0
    for (id, t_start) in stats[:repair_start_times]
        t_end = get(stats[:repair_end_times], id, crash_time)
        total_busy += (t_end - t_start)
    end
    utilization = total_busy / (crash_time * params.num_repairmen)

    if isempty(stats[:queue_history])
        avg_queue = 0.0
    else
        total_time = 0.0
        weighted = 0.0
        prev_t = 0.0
        for (t, q) in stats[:queue_history]
            dt = t - prev_t
            weighted += q * dt
            total_time += dt
            prev_t = t
        end
        avg_queue = weighted / total_time
    end

    if verbose
        println("--- Ross (N=$(params.N), S=$(params.S), repairmen=$(params.num_repairmen)) ---")
        println("Crash time: $(round(crash_time, digits=2)) h")
        println("Failures: $(stats[:failures]), Repairs: $(stats[:repairs])")
        println("Utilization: $(round(100*utilization, digits=1))%")
        println("Avg queue length: $(round(avg_queue, digits=2))")
    end

    return RossRunResult(crash_time, utilization, avg_queue,
                         stats[:operational_history], stats[:queue_history])
end

# ## Множественные прогоны

function run_ross_multiple(params::RossParams, num_runs::Int=5; verbose=false)
    results = []
    for run in 1:num_runs
        p = RossParams(; (pairs(params))..., seed=params.seed + run*1000)
        res = run_ross_single(p, verbose=verbose)
        push!(results, res)
    end
    crash_times = [r.crash_time for r in results]
    utils = [r.repairman_utilization for r in results]
    queues = [r.avg_queue_length for r in results]
    return (results=results,
            mean_crash_time=mean(crash_times), std_crash_time=std(crash_times),
            mean_utilization=mean(utils), std_utilization=std(utils),
            mean_queue_length=mean(queues), std_queue_length=std(queues))
end

# ## Визуализация

function plot_ross_run(res::RossRunResult, params::RossParams, suffix="")
    p1 = plot([t for (t,_) in res.operational_history],
              [n for (_,n) in res.operational_history],
              title="Number of operational machines", xlabel="Time (hours)",
              ylabel="Machines", label="simulation", linewidth=2,
              ylims=(0, params.N+params.S+1))
    hline!([params.N], label="Required (N)", linestyle=:dash, color=:red)

    p2 = plot([t for (t,_) in res.queue_history],
              [q for (_,q) in res.queue_history],
              title="Repair queue length", xlabel="Time (hours)",
              ylabel="Queue length", label="queue", linewidth=1.5,
              fillrange=0, alpha=0.3, color=:blue)

    p = plot(p1, p2, layout=(2,1), size=(800,600))
    fn = "ross_$(params.N)_$(params.S)_r$(params.num_repairmen)$suffix.png"
    savefig(plotsdir(fn))
    return p
end

# ## Параметрическое исследование

function ross_parametric_study()
    mkpath(datadir("ross"))
    mkpath(plotsdir())

    # 1. Влияние числа ремонтников
    println("\n🔧 Влияние числа ремонтников")
    repairmen_range = [1,2,3,4]
    results_repairmen = []
    for r in repairmen_range
        p = RossParams(num_repairmen=r, seed=123)
        multi = run_ross_multiple(p, 3, verbose=false)
        push!(results_repairmen, (r=r, multi=multi))
        println("  $r ремонтник(ов): среднее время до краха = $(round(multi.mean_crash_time, digits=1)) ± $(round(multi.std_crash_time, digits=1)) ч")
    end
    df_rep = DataFrame(r=[r for (r,_) in results_repairmen],
                       crash=[multi.mean_crash_time for (_,multi) in results_repairmen],
                       std=[multi.std_crash_time for (_,multi) in results_repairmen])
    p1 = plot(df_rep.r, df_rep.crash, yerr=df_rep.std, marker=:circle, linewidth=2,
              xlabel="Number of repairmen", ylabel="Mean crash time (hours)",
              title="Effect of repairmen count", legend=false)
    savefig(plotsdir("ross_repairmen_effect.png"))

    # 2. Влияние числа основных машин N
    println("\n🏭 Влияние числа основных машин N")
    N_range = [5,10,15,20,25]
    results_N = []
    for n in N_range
        p = RossParams(N=n, S=3, num_repairmen=2, seed=456)
        multi = run_ross_multiple(p, 3, verbose=false)
        push!(results_N, (N=n, multi=multi))
        println("  N=$n: среднее время до краха = $(round(multi.mean_crash_time, digits=1)) ± $(round(multi.std_crash_time, digits=1)) ч")
    end
    df_N = DataFrame(N=[n for (n,_) in results_N],
                     crash=[multi.mean_crash_time for (_,multi) in results_N],
                     std=[multi.std_crash_time for (_,multi) in results_N])
    p2 = plot(df_N.N, df_N.crash, yerr=df_N.std, marker=:square, linewidth=2,
              xlabel="Number of working machines N", ylabel="Mean crash time (hours)",
              title="Effect of N (S=3, 2 repairmen)", legend=false)
    savefig(plotsdir("ross_N_effect.png"))

    # 3. Влияние числа запасных машин S
    println("\n💾 Влияние числа запасных машин S")
    S_range = [1,2,3,4,5,6]
    results_S = []
    for s in S_range
        p = RossParams(N=10, S=s, num_repairmen=2, seed=789)
        multi = run_ross_multiple(p, 3, verbose=false)
        push!(results_S, (S=s, multi=multi))
        println("  S=$s: crash time = $(round(multi.mean_crash_time, digits=1)) ч")
    end
    df_S = DataFrame(S=[s for (s,_) in results_S],
                     crash=[multi.mean_crash_time for (_,multi) in results_S])
    p3 = plot(df_S.S, df_S.crash, marker=:diamond, linewidth=2,
              xlabel="Number of spare machines S", ylabel="Mean crash time (hours)",
              title="Effect of S (N=10, 2 repairmen)", legend=false)
    savefig(plotsdir("ross_S_effect.png"))

    # 4. Детальный прогон для N=10,S=3,2 ремонтника
    println("\n📊 Детальный прогон для N=10,S=3,2 ремонтника")
    p_detail = RossParams(N=10, S=3, num_repairmen=2, seed=999)
    res_detail = run_ross_single(p_detail, verbose=true)
    plot_ross_run(res_detail, p_detail, "_detail")
    df_oper = DataFrame(time=[t for (t,_) in res_detail.operational_history],
                        operational=[n for (_,n) in res_detail.operational_history])
    df_queue = DataFrame(time=[t for (t,_) in res_detail.queue_history],
                         queue=[q for (_,q) in res_detail.queue_history])
    CSV.write(datadir("ross", "operational_history.csv"), df_oper)
    CSV.write(datadir("ross", "queue_history.csv"), df_queue)

    @save datadir("ross", "ross_parametric_summary.jld2") df_rep df_N df_S
end

# ## Сравнение с аналитическим решением

function ross_analytical_comparison()
    println("\n Сравнение с аналитическим решением (один ремонтник)")
    p_ana = RossParams(N=10, S=3, num_repairmen=1, seed=123)
    sim_res = run_ross_multiple(p_ana, 10)
    analytical_approx = 45.0   # приближённое значение из теории
    println("Симуляция: среднее время до краха = $(round(sim_res.mean_crash_time, digits=1)) ± $(round(sim_res.std_crash_time, digits=1)) ч")
    println("Аналитическая оценка (приближённая): ≈ $analytical_approx ч")
    println("Относительное отклонение: $(round(abs(sim_res.mean_crash_time - analytical_approx)/analytical_approx*100, digits=1))%")
end

# ## Выполнение всех заданий

println("="^60)
println("Задание 7.2.4: Модель Росса")
println("="^60)

# Базовый прогон с 1 ремонтником
println("\n1️⃣ Базовый прогон (N=10, S=3, 1 ремонтник)")
p_base = RossParams()
res_base = run_ross_single(p_base)
plot_ross_run(res_base, p_base, "_base")

# Прогон с 2 и 3 ремонтниками
println("\n2️⃣ Прогон с 2 ремонтниками")
p2 = RossParams(num_repairmen=2, seed=42)
res2 = run_ross_single(p2)
plot_ross_run(res2, p2, "_2rep")

println("\n3️⃣ Прогон с 3 ремонтниками")
p3 = RossParams(num_repairmen=3, seed=42)
res3 = run_ross_single(p3)
plot_ross_run(res3, p3, "_3rep")

# Параметрическое исследование
ross_parametric_study()

# Сравнение с аналитикой
ross_analytical_comparison()

println("\n✅ Модель Росса выполнена. Результаты в data/ross/ и plots/")
