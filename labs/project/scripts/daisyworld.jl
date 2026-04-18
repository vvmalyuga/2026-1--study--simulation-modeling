## В модели Daisyworld агентами являются чёрные и белые маргаритки. Они живут на клеточной сетке (среда).


## Правила:

### Маргаритки изменяют локальную температуру за счёт разного альбедо.
### Температура влияет на вероятность размножения (чем ближе к оптимуму, тем выше шанс заселить соседнюю пустую клетку).
### Агенты стареют и умирают после определённого возраста.
### Среда (температура) диффундирует между клетками.

## Агенты
### Маргаритки двух типов — чёрные (black) и белые (white). Каждая маргаритка занимает одну клетку сетки и имеет возраст (количество шагов с момента появления).

## Параметры
### luminosity – солнечная постоянная (может изменяться со временем).
### albedo_black, albedo_white – альбедо чёрных и белых маргариток.
### surface_albedo — альбедо пустой почвы.
### max_age — максимальный возраст маргаритки.

## Динамика
### Для каждой клетки рассчитывается локальная температура.

### Каждая маргаритка может погибнуть с вероятностью, зависящей от температуры. Если температура выходит за допустимый диапазон, вероятность смерти повышается.

### Если клетка пуста, на неё может попасть семя от соседней маргаритки. Вероятность успешного прорастания зависит от температуры клетки. Если вероятность превышает случайное число, на пустой клетке появляется новая маргаритка того же цвета, что и родительская.





using DrWatson
using Agents
using CairoMakie


script_dir = @__DIR__
src_dir = joinpath(script_dir, "..", "src")
plots_dir = joinpath(script_dir, "..", "plots")
mkpath(plots_dir)


include(joinpath(src_dir, "daisyworld.jl"))

model = daisyworld()

daisycolor(a::Daisy) = a.breed

plotkwargs = (
    agent_color = daisycolor,
    agent_size = 20,
    agent_marker = '✿',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),),
)

plt1, _ = abmplot(model; plotkwargs...)
save(joinpath(plots_dir, "daisy_step001.png"), plt1)

## Модель через пять шагов 
# 
#


step!(model, 5)
plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)
save(joinpath(plots_dir, "daisy_step005.png"), plt2)

## Модель через сорок шагов 
# 



step!(model, 40)
plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)
save(joinpath(plots_dir, "daisy_step040.png"), plt3)
