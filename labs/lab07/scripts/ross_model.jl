#!/usr/bin/env julia
"""
Модель Росса - рабочая версия с ручным счётчиком очереди
"""

using ConcurrentSim
using Distributions
using Random
using ResumableFunctions
using Plots

struct RossParameters
    N::Int
    S::Int
    mean_time_to_fail::Float64
    mean_repair_time::Float64
    num_repairmen::Int
    seed::Int
end

struct RossResults
    crash_time::Float64
    repairman_utilization::Float64
    avg_queue_length::Float64
    operational_history::Vector{Tuple{Float64,Int}}
    queue_history::Vector{Tuple{Float64,Int}}
end

function default_parameters(; N=10, S=3, mean_time_to_fail=100.0, mean_repair_time=1.0, num_repairmen=1, seed=42)
    RossParameters(N, S, mean_time_to_fail, mean_repair_time, num_repairmen, seed)
end

# Счетчик для длины очереди - используем ручной счётчик из stats
@resumable function queue_counter(env::Environment, stats::Dict, interval::Float64)
    while true
        @yield timeout(env, interval)
        queue_len = stats[:queue_length][]
        push!(stats[:queue_history], (now(env), queue_len))
    end
end

# Процесс одной машины
@resumable function machine(env::Environment, repair_queue::Resource, params::RossParameters, stats::Dict, id::Int)
    while true
        # Работа
        work_time = rand(Exponential(params.mean_time_to_fail))
        @yield timeout(env, work_time)
        
        # Отказ
        stats[:failures] += 1
        
        # Взять из резерва
        if stats[:spares] > 0
            stats[:spares] -= 1
        else
            stats[:crash_time] = now(env)
            throw(StopSimulation("No spares at time $(now(env))"))
        end
        
        # Ремонт - увеличиваем счётчик очереди перед запросом
        stats[:queue_length][] += 1
        @yield request(repair_queue)
        stats[:queue_length][] -= 1
        
        stats[:repair_start_times][id] = now(env)
        repair_time = rand(Exponential(params.mean_repair_time))
        @yield timeout(env, repair_time)
        stats[:repair_end_times][id] = now(env)
        @yield release(repair_queue)
        
        # Пополнение резерва
        stats[:spares] += 1
        stats[:repairs] += 1
    end
end

# Мониторинг состояния системы
@resumable function system_monitor(env::Environment, stats::Dict, params::RossParameters, interval::Float64)
    while true
        @yield timeout(env, interval)
        t = now(env)
        operational = stats[:spares] + params.N
        push!(stats[:operational_history], (t, operational))
    end
end

# Запуск одной симуляции
function run_simulation(params::RossParameters; verbose=true)
    Random.seed!(params.seed)
    env = Simulation()
    repair_queue = Resource(env, params.num_repairmen)
    
    stats = Dict(
        :failures => 0,
        :repairs => 0,
        :spares => params.S,
        :crash_time => Inf,
        :queue_length => Ref(0),  # Ручной счётчик очереди
        :repair_start_times => Dict{Int,Float64}(),
        :repair_end_times => Dict{Int,Float64}(),
        :operational_history => Vector{Tuple{Float64,Int}}(),
        :queue_history => Vector{Tuple{Float64,Int}}()
    )
    
    # Запуск мониторов
    @process system_monitor(env, stats, params, 1.0)
    @process queue_counter(env, stats, 1.0)
    
    # Запуск N работающих машин
    for i in 1:params.N
        @process machine(env, repair_queue, params, stats, i)
    end
    
    try
        run(env)
    catch e
        if !isa(e, StopSimulation)
            rethrow()
        end
    end
    
    crash_time = stats[:crash_time]
    
    # Загрузка ремонтников
    total_busy = 0.0
    for (id, t_start) in stats[:repair_start_times]
        t_end = get(stats[:repair_end_times], id, crash_time)
        total_busy += (t_end - t_start)
    end
    utilization = total_busy > 0 ? total_busy / (crash_time * params.num_repairmen) : 0.0
    
    # Средняя длина очереди
    if isempty(stats[:queue_history])
        avg_queue = 0.0
    else
        avg_queue = mean(q for (_, q) in stats[:queue_history])
    end
    
    if verbose
        println("Crash time: $(round(crash_time, digits=2)) hours")
        println("Failures: $(stats[:failures]), Repairs: $(stats[:repairs])")
        println("Utilization: $(round(100*utilization, digits=1))%")
        println("Avg queue length: $(round(avg_queue, digits=2))")
    end
    
    RossResults(crash_time, utilization, avg_queue,
                stats[:operational_history], stats[:queue_history])
end

# Множественные прогоны
function run_multiple_simulations(params::RossParameters, num_runs::Int=10; verbose=false)
    results = []
    for run in 1:num_runs
        verbose && println("Run $run/$num_runs")
        p = RossParameters(params.N, params.S, params.mean_time_to_fail, params.mean_repair_time,
                          params.num_repairmen, params.seed + run)
        res = run_simulation(p, verbose=verbose)
        push!(results, res)
    end
    crash_times = [r.crash_time for r in results]
    utils = [r.repairman_utilization for r in results]
    queues = [r.avg_queue_length for r in results]
    return (; results, mean_crash_time=mean(crash_times), std_crash_time=std(crash_times),
            mean_utilization=mean(utils), std_utilization=std(utils),
            mean_queue_length=mean(queues), std_queue_length=std(queues))
end

# Построение графиков
function plot_results(res::RossResults, params::RossParameters)
    p1 = plot([t for (t,_) in res.operational_history],
              [n for (_,n) in res.operational_history],
              title="Operational machines vs time", xlabel="Time (hours)",
              ylabel="Machines", label="Simulation", linewidth=2,
              ylims=(0, params.N+params.S))
    hline!([params.N], label="Required (N)", linestyle=:dash)
    
    p2 = plot([t for (t,_) in res.queue_history],
              [q for (_,q) in res.queue_history],
              title="Repair queue length", xlabel="Time (hours)",
              ylabel="Queue length", label="Queue", linewidth=2, fillrange=0, alpha=0.3)
    
    plot(p1, p2, layout=(2,1), size=(800,600))
end

# Сравнение количества ремонтников
function compare_repairmen()
    println("\n=== Сравнение количества ремонтников ===")
    for r in [1, 2, 3, 4]
        params = default_parameters(N=10, S=3, num_repairmen=r, seed=123)
        res = run_multiple_simulations(params, 5, verbose=false)
        println("$r repairman(ы): mean crash time = $(round(res.mean_crash_time, digits=2)) ± $(round(res.std_crash_time, digits=2)) hours")
    end
end

# Сравнение количества машин
function compare_machines()
    println("\n=== Сравнение количества машин ===")
    for N in [5, 10, 15, 20]
        params = default_parameters(N=N, S=3, num_repairmen=2, seed=123)
        res = run_multiple_simulations(params, 5, verbose=false)
        println("N=$N: mean crash time = $(round(res.mean_crash_time, digits=2)) ± $(round(res.std_crash_time, digits=2)) hours")
    end
end

# Тестовый прогон с разными параметрами
function test_parameters()
    println("\n=== Тест разных параметров ===")
    
    # Разное количество запасных машин
    println("\nРазное количество запасных машин (S):")
    for S in [1, 2, 3, 4, 5]
        params = default_parameters(N=10, S=S, num_repairmen=1, seed=123)
        res = run_simulation(params, verbose=false)
        println("  S=$S: crash time = $(round(res.crash_time, digits=2)) hours")
    end
    
    # Разные времена работы
    println("\nРазные средние времена работы (MTBF):")
    for mtbf in [50.0, 100.0, 200.0]
        params = default_parameters(N=10, S=3, mean_time_to_fail=mtbf, num_repairmen=1, seed=123)
        res = run_simulation(params, verbose=false)
        println("  MTBF=$(mtbf)h: crash time = $(round(res.crash_time, digits=2)) hours")
    end
end

# ========== ЗАПУСК ==========
println("="^60)
println("МОДЕЛЬ РОССА - РЕЗЕРВИРОВАНИЕ И РЕМОНТ")
println("="^60)

println("\n1️⃣ Базовый запуск (N=10, S=3, 1 ремонтник)")
params = default_parameters()
res = run_simulation(params)

println("\n2️⃣ График")
p = plot_results(res, params)
display(p)
savefig(p, "ross_basic.png")
println("   Сохранён ross_basic.png")

println("\n3️⃣ Сравнение числа ремонтников")
compare_repairmen()

println("\n4️⃣ Сравнение числа машин")
compare_machines()

println("\n5️⃣ Тест разных параметров")
test_parameters()

println("\n✅ Готово!")
