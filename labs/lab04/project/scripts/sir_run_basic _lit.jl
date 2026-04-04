# ### Базовый эксперимент с агентной моделью SIR
#
# **Цель:** запустить модель SIR с параметрами по умолчанию, собрать динамику
# численности агентов (S, I, R) и построить график. Этот скрипт служит для
# проверки работоспособности модели и получения первичного понимания
# эпидемического процесса.
#
# #### Теоретическое введение
#
# Модель SIR (Susceptible–Infectious–Recovered) описывает распространение
# инфекции в закрытой популяции. Классическая модель задаётся системой ОДУ:
# ```
# dS/dt = -β·S·I/N
# dI/dt =  β·S·I/N - γ·I
# dR/dt =  γ·I
# ```
# где β – коэффициент передачи, γ – скорость выздоровления.
#
# Агентная реализация снимает ограничения однородности и детерминизма:
# каждый человек моделируется индивидуально, взаимодействия локальны,
# процессы стохастичны. В данной модели агенты перемещаются между
# тремя городами (узлами графа) и могут заражать друг друга.
#
# #### Параметры эксперимента
#
# - `Ns` – численность населения в каждом из трёх городов.
# - `β_und`, `β_det` – интенсивность заражения невыявленными и выявленными.
# - `infection_period` – длительность болезни (дней).
# - `detection_time` – время до выявления заболевания.
# - `death_rate` – вероятность смерти при завершении болезни.
# - `reinfection_probability` – вероятность повторного заражения.
# - `Is` – начальное количество инфицированных в каждом городе.
# - `seed` – зерно генератора случайных чисел.
# - `n_steps` – количество дней симуляции.


using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots
using JLD2

include(srcdir("sir_model.jl"))

# #### Параметры эксперимента
#
params = Dict(
    :Ns => [1000, 1000, 1000],
    :β_und => [0.5, 0.5, 0.5],
    :β_det => [0.05, 0.05, 0.05],
    :infection_period => 14,
    :detection_time => 7,
    :death_rate => 0.02,
    :reinfection_probability => 0.1,
    :Is => [0, 0, 1],
    :seed => 42,
    :n_steps => 100,
)

# #### Инициализация модели
model = initialize_sir(; params...)

# #### Подготовка массивов для хранения данных
times = Int[]
S_vals = Int[]
I_vals = Int[]
R_vals = Int[]
total_vals = Int[]

# #### Запуск симуляции вручную
for step = 1:params[:n_steps]
    Agents.step!(model, 1)

    push!(times, step)
    push!(S_vals, susceptible_count(model))
    push!(I_vals, infected_count(model))
    push!(R_vals, recovered_count(model))
    push!(total_vals, total_count(model))
end

# #### Создаём DataFrame для удобства (опционально)
agent_df =
    DataFrame(time = times, susceptible = S_vals, infected = I_vals, recovered = R_vals)
model_df = DataFrame(time = times, total = total_vals)

# #### Визуализация
plot(
    agent_df.time,
    agent_df.susceptible,
    label = "Восприимчивые",
    xlabel = "Дни",
    ylabel = "Количество",
)
plot!(agent_df.time, agent_df.infected, label = "Инфицированные")
plot!(agent_df.time, agent_df.recovered, label = "Выздоровевшие")
plot!(agent_df.time, model_df.total, label = "Всего (включая умерших)", linestyle = :dash)
savefig(plotsdir("sir_basic_dynamics.png"))

# #### Сохранение данных
@save datadir("sir_basic_agent.jld2") agent_df
@save datadir("sir_basic_model.jld2") model_df
