#!/usr/bin/env julia
# add_packages.jl - Установка пакетов

using Pkg
Pkg.activate(".")

packages = [
    "DrWatson",           # Организация проекта
    "DifferentialEquations", # Решение ОДУ
    "Plots",              # Визуализация
    "StatsPlots",         # Статистические графики
    "LaTeXStrings",       # Формулы на графиках
    "DataFrames",         # Таблицы данных
    "Tables",             # Интерфейс таблиц
    "CSV",                # Работа с CSV
    "JLD2",               # Сохранение данных
    "Literate",           # Литературное программирование
    "IJulia",             # Jupyter notebook
    "Quarto",             # Интеграция с Quarto
    "BenchmarkTools",     # Бенчмаркинг
    "FFTW",               # Быстрое преобразование Фурье
    "SimpleDiffEq"        # Простые решатели ОДУ
]

println("="^60)
println("УСТАНОВКА ПАКЕТОВ")
println("="^60)

for pkg in packages
    print("Установка $pkg... ")
    try
        Pkg.add(pkg)
        println("✓")
    catch e
        println("✗ Ошибка: $e")
    end
end

println("\nУстановка завершена!")
