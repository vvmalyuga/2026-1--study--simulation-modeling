# ### Анализ порога эпидемии
using DrWatson
@quickactivate "project"
using DataFrames, CSV, Plots

# #### Загружаем результаты сканирования β
df = CSV.read(datadir("beta_scan_all.csv"), DataFrame)

# #### Группируем по β и усредняем
using Statistics
grouped = combine(groupby(df, :beta), :peak => mean => :mean_peak)

# #### Находим минимальное β, при котором пик > 5% от популяции (3000 * 0.05 = 150)
threshold_beta = minimum(grouped[grouped.mean_peak .* 3000 .> 150, :beta])
println("Минимальное β_und для эпидемии (пик > 150): $threshold_beta")

# #### Теоретический порог R₀ = 1
infection_period = 14
detection_time = 7
β_det = 0.05
# #### R₀ = β_und * detection_time + β_det * (infection_period - detection_time) = 1
β_und_theoretical = (1 - β_det * (infection_period - detection_time)) / detection_time
println("Теоретический порог β_und (R₀=1): $(round(β_und_theoretical, digits=3))")

# #### График с порогом
plot(grouped.beta, grouped.mean_peak .* 3000, label="Пик заболеваемости", xlabel="β_und", ylabel="Число инфицированных в пике")
vline!([threshold_beta], label="Эмпирический порог β=$threshold_beta", linestyle=:dash)
hline!([150], label="5% порог (150 чел)", linestyle=:dot)
savefig(plotsdir("threshold_analysis.png"))
