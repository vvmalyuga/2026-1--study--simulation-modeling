#!/usr/bin/env julia
# tangle.jl - Генератор отчетов из Literate-скриптов
# Использование: julia tangle.jl <путь_к_скрипту>

using Literate
using DrWatson

function main()
    if length(ARGS) == 0
        println("""
        Использование: julia tangle.jl <путь_к_скрипту>
        Примеры:
        julia tangle.jl daisyworld_lit.jl
        """)
        return
    end

    script_path = ARGS[1]
    if !isfile(script_path)
        error("Файл не найден: $script_path")
    end

    # Пути и имена
    script_name = splitext(basename(script_path))[1]
    println("Генерация из: $script_path")

    # Определяем корень проекта (на два уровня выше scripts)
    project_root = joinpath(@__DIR__, "..", "..", "project")
    mkpath(project_root)

    # Чистый скрипт (без комментариев)
    clean_scripts_dir = joinpath(project_root, "scripts", script_name)
    mkpath(clean_scripts_dir)
    Literate.script(script_path, clean_scripts_dir; credit=false)
    println(" ✓ Чистый скрипт: $(clean_scripts_dir)/$(script_name).jl")

    # Quarto-документ
    quarto_dir = joinpath(project_root, "markdown", script_name)
    mkpath(quarto_dir)
    Literate.markdown(script_path, quarto_dir;
                      flavor = Literate.QuartoFlavor(),
                      name = script_name, credit = false)
    println(" ✓ Quarto: $(quarto_dir)/$(script_name).qmd")

    # Jupyter notebook
    notebooks_dir = joinpath(project_root, "notebooks", script_name)
    mkpath(notebooks_dir)
    Literate.notebook(script_path, notebooks_dir, name = script_name;
                      execute = false, credit = false)
    println(" ✓ Notebook: $(notebooks_dir)/$(script_name).ipynb")

    println("\nГотово! Все файлы созданы.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
