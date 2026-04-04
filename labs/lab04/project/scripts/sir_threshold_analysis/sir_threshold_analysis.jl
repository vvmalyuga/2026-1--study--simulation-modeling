using DrWatson
@quickactivate "project"
using DataFrames, CSV, Plots

df = CSV.read(datadir("beta_scan_all.csv"), DataFrame)

using Statistics
grouped = combine(groupby(df, :beta), :peak => mean => :mean_peak)

threshold_beta = minimum(grouped[grouped.mean_peak .* 3000 .> 150, :beta])
println("Минимальное β_und для эпидемии (пик > 150): $threshold_beta")

infection_period = 14
detection_time = 7
β_det = 0.05

β_und_theoretical = (1 - β_det * (infection_period - detection_time)) / detection_time
println("Теоретический порог β_und (R₀=1): $(round(β_und_theoretical, digits=3))")

plot(grouped.beta, grouped.mean_peak .* 3000, label="Пик заболеваемости", xlabel="β_und", ylabel="Число инфицированных в пике")
vline!([threshold_beta], label="Эмпирический порог β=$threshold_beta", linestyle=:dash)
hline!([150], label="5% порог (150 чел)", linestyle=:dot)
savefig(plotsdir("threshold_analysis.png"))
