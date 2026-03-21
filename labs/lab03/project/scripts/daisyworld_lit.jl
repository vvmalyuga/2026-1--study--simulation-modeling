# # Базовая визуализация Daisyworld
#
# Создадим модель и отобразим её состояние на нескольких шагах:
# начальное, после 5 шагов и после 40 шагов.
# Используется тепловая карта температуры, маргаритки отображаются символами.

# ## Инициализация (проект активирован через командную строку)
using DrWatson
using Agents
using CairoMakie
using Plots

# Подключаем определение модели (относительный путь от скрипта)
include(joinpath(@__DIR__, "..", "src", "daisyworld.jl"))

# ## Настройки визуализации
daisycolor(a::Daisy) = a.breed

plotkwargs = (
    agent_color = daisycolor,
    agent_size = 20,
    agent_marker = '✿',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),),
)

# ## Запуск и сохранение кадров
model = daisyworld()

plt1, _ = abmplot(model; plotkwargs...)

step!(model, 5)
plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

step!(model, 35)  # итого 40
plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

# Сохраняем графики в папку `plots` на уровне выше скрипта
plots_dir = joinpath(@__DIR__, "..", "plots")
mkpath(plots_dir)

save(joinpath(plots_dir, "daisy_step001.png"), plt1)
save(joinpath(plots_dir, "daisy_step005.png"), plt2)
save(joinpath(plots_dir, "daisy_step040.png"), plt3)

println("Графики сохранены в $plots_dir")
