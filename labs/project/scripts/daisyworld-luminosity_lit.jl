# # Динамика модели при изменении солнечной активности
#
# Используем сценарий `:ramp`, при котором светимость сначала увеличивается,
# а затем уменьшается. Строим графики численности маргариток, средней температуры
# и светимости.


using DrWatson
using Agents
using CairoMakie
using DataFrames
using StatsBase

include(joinpath(@__DIR__, "..", "src", "daisyworld.jl"))

# ## Агрегаторы
black(a) = a.breed == :black
white(a) = a.breed == :white
adata = [(black, count), (white, count)]

# ## Запуск модели со сценарием :ramp
model = daisyworld(solar_luminosity = 1.0, scenario = :ramp)

# Функция для средней температуры
temperature(model) = StatsBase.mean(model.temperature)
mdata = [temperature, :solar_luminosity]

agent_df, model_df = run!(model, 1000; adata = adata, mdata = mdata)

# ## Построение комплексного графика
figure = CairoMakie.Figure(size = (600, 600))

# График численности
ax1 = Axis(figure[1, 1], ylabel = "daisy count")
blackl = lines!(ax1, agent_df[!, :time], agent_df[!, :count_black], color = :red)
whitel = lines!(ax1, agent_df[!, :time], agent_df[!, :count_white], color = :blue)
figure[1, 2] = Legend(figure, [blackl, whitel], ["black", "white"])

# График температуры
ax2 = Axis(figure[2, 1], ylabel = "temperature")
lines!(ax2, model_df[!, :time], model_df[!, :temperature], color = :red)

# График светимости
ax3 = Axis(figure[3, 1], xlabel = "tick", ylabel = "luminosity")
lines!(ax3, model_df[!, :time], model_df[!, :solar_luminosity], color = :red)

# Скрываем подписи на оси x для верхних графиков
for ax in (ax1, ax2)
    ax.xticklabelsvisible = false
end

plots_dir = joinpath(@__DIR__, "..", "plots")
mkpath(plots_dir)
save(joinpath(plots_dir, "daisy_luminosity.png"), figure)

println("График динамики сохранён в $plots_dir/daisy_luminosity.png")
