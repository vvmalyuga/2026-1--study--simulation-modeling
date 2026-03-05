# # Основные модели динамических систем
#
# В данной лабораторной работе рассматриваются:
#
# - модель распространения инфекции SIR
# - модель хищник-жертва Лотки–Вольтерры
#
# ## Подключение пакетов

using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]

mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Модель SIR

function sir!(du,u,p,t)

    S,I,R = u
    β,γ = p

    du[1] = -β*S*I
    du[2] = β*S*I - γ*I
    du[3] = γ*I

end

u0 = [0.99,0.01,0.0]
p = (0.3,0.1)
tspan = (0.0,100.0)

prob = ODEProblem(sir!,u0,tspan,p)
sol = solve(prob, Tsit5(), saveat=0.1)

p1 = plot(sol,
label=["S" "I" "R"],
title="SIR модель",
xlabel="Время",
ylabel="Популяция")

savefig(plotsdir(script_name,"sir_model.png"))

# ## Модель Лотки–Вольтерры

function lotka!(du,u,p,t)

    x,y = u
    α,β,δ,γ = p

    du[1] = α*x - β*x*y
    du[2] = δ*x*y - γ*y

end

u0 = [10.0,5.0]
p = (1.5,1.0,1.0,3.0)
tspan = (0.0,50.0)

prob = ODEProblem(lotka!,u0,tspan,p)
sol = solve(prob, Tsit5(), saveat=0.1)

p2 = plot(sol,
label=["Жертвы" "Хищники"],
title="Модель Лотки-Вольтерры",
xlabel="Время",
ylabel="Популяция")

savefig(plotsdir(script_name,"lotka_model.png"))

# ## Сохранение данных

df = DataFrame(t = sol.t, x = first.(sol.u), y = getindex.(sol.u,2))

@save datadir(script_name,"lotka_results.jld2") df
