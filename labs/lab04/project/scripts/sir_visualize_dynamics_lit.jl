# ### Сводная визуализация результатов сканирования β
#
# **Цель:** загрузить данные из файла `beta_scan_all.csv` (полученного в
# результате работы `sir_scan_beta.jl`) и построить составной график из
# трёх панелей:
# 1. Пик эпидемии и конечная доля инфицированных,
# 2. Число умерших,
# 3. Доля выздоровевших.
#
# Скрипт предназначен для итогового отчёта и **не выполняет новых симуляций**,
# а только визуализирует уже полученные данные.

using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots, CSV

include(srcdir("sir_model.jl"))

# #### Загружаем результаты сканирования
df = CSV.read(datadir("beta_scan_all.csv"), DataFrame)

# #### Создаём составной график
p1 = plot(df.beta, df.peak, label = "Пик", xlabel = "β", ylabel = "Доля инфицированных")
plot!(p1, df.beta, df.final_inf, label = "Конечная")

p2 = plot(df.beta, df.deaths, xlabel = "β", ylabel = "Число умерших")

p3 = plot(df.beta, df.final_rec, xlabel = "β", ylabel = "Доля выздоровевших")

plot(p1, p2, p3, layout = (3, 1), size = (800, 900))
savefig(plotsdir("comprehensive_analysis.png"))
