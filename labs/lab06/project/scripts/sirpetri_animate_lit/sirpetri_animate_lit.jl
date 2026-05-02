using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
using Plots

β = 0.3
γ = 0.1
tmax = 100.0

net, u0, _ = build_sir_network(β, γ)
df = simulate_deterministic(net, u0, (0.0, tmax); saveat=0.2, rates=[β, γ])

anim = @animate for row in eachrow(df)
    bar(["S", "I", "R"], [row.S, row.I, row.R],
        legend = false,
        ylims = (0, 1000),
        xlabel = "Состояние",
        ylabel = "Популяция",
        title = "Время = $(round(row.time, digits=1))"
    )
end

gif(anim, plotsdir("sir_animation.gif"), fps = 10)

if isinteractive()
    try
        using IJulia  # доступен внутри Jupyter
        display("image/gif", read(plotsdir("sir_animation.gif")))
    catch e
        @warn "Не удалось отобразить анимацию в ноутбуке: $e"
    end
end

println("Анимация сохранена в plots/sir_animation.gif")
