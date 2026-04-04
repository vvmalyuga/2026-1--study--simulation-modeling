using DrWatson
@quickactivate "project"
using DataFrames, CSV, Plots, Statistics

df = CSV.read(datadir("migration_scan_all.csv"), DataFrame)
grouped = combine(groupby(df, :migration_intensity), :peak_time => mean => :mean_peak_time)

opt_intensity = grouped[argmin(grouped.mean_peak_time), :migration_intensity]
println("Интенсивность миграции с минимальным временем до пика: $opt_intensity")

plot(grouped.migration_intensity, grouped.mean_peak_time, marker=:circle, xlabel="Интенсивность миграции", ylabel="Время до пика (дни)", title="Зависимость времени пика от миграции")
vline!([opt_intensity], label="Оптимум = $opt_intensity", linestyle=:dash)
savefig(plotsdir("migration_optimum.png"))
