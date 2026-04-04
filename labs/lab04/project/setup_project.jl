using Pkg
Pkg.activate(".")
packages = [
    "DrWatson", "Agents", "DifferentialEquations", "Plots",
    "DataFrames", "Literate", "JLD2", "CSV", "CairoMakie", "StatsBase"
]
Pkg.add(packages)
