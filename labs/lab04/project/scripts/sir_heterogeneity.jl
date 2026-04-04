# ### Влияние гетерогенности β_und в разных городах
using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots
include(srcdir("sir_model.jl"))

params = Dict(
    :Ns => [1000, 1000, 1000],
    :β_und => [0.8, 0.3, 0.5],  # разные значения для трёх городов
    :β_det => [0.08, 0.03, 0.05],
    :infection_period => 14,
    :detection_time => 7,
    :death_rate => 0.02,
    :reinfection_probability => 0.1,
    :Is => [1, 0, 0],
    :seed => 42,
    :n_steps => 100,
)

model = initialize_sir(; params...)

# #### Сбор данных по городам
times = Int[]
S_city = zeros(Int, params[:n_steps], 3)
I_city = zeros(Int, params[:n_steps], 3)
R_city = zeros(Int, params[:n_steps], 3)

for step in 1:params[:n_steps]
    Agents.step!(model, 1)
    push!(times, step)
    for city in 1:3
        agents = [a for a in allagents(model) if a.pos == city]
        S_city[step, city] = count(a.status == :S for a in agents)
        I_city[step, city] = count(a.status == :I for a in agents)
        R_city[step, city] = count(a.status == :R for a in agents)
    end
end

# #### Построение графиков
p = plot(layout=(3,1), size=(800,900))
for city in 1:3
    plot!(p[city], times, I_city[:, city], label="Город $city, β=$(params[:β_und][city])", xlabel="Дни", ylabel="Инфицированные")
end
savefig(plotsdir("heterogeneity.png"))
