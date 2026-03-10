using Plots, PGFPlotsX
using LaTeXStrings
using UnPack

using DifferentialEquations
default(linewidth = 3, background = raw"#FAFAFA")
theme(:wong2)
pgfplotsx()

PLOTPATH = "3-12/figures"

## Plotting Utils
Nspace = range(0, 0.1, 1001)

## Profit function
struct Technology{S}
    a::S
    b::S
end
function profit(N, technology::Technology)
    @unpack a, b = technology
    return a * N^b
end

existing = Technology(1031., 1.448 / 100)
adapted = Technology(1094., 0.0811 / 100)

N₀ = 6e-6

let
    profitfig = plot(xlabel = L"Resource pool $N(t)$", ylabel = L"Log-profits $\log \pi_{i}(t) / \pi_{i}(0)$", legend_title = L"i", size = 200 .* (16 / 9, 1))

    plot!(profitfig, Nspace, N -> log(profit(N, existing) / profit(N₀, existing)), label = L"0")
    plot!(profitfig, Nspace, N -> log(profit(N, adapted) / profit(N₀, adapted)), label = L"1")

    savefig(profitfig, joinpath(PLOTPATH, "profit.tikz"))

    profitfig
end


## Profit dynamics
struct Beliefs{S}
    α::S
    σ::S
end

optimistic = Beliefs(-0.126, 1.196)
pessimistic = Beliefs(-0.612, 1.067)

function μ(technology::Technology, belief::Beliefs)
    @unpack b = technology
    @unpack α, σ = belief

    b * α + b * (b - 1) / 2 * σ^2
end

function profitdrift(x, parameters, t)
    technology, beliefs = parameters
    return μ(technology, beliefs)
end
function profitnoise(x, parameters, t)
    technology, beliefs = parameters
    
    return technology.b * beliefs.σ^2
end

parameters = Base.product((existing, adapted), (pessimistic, optimistic)) |> collect
system = SDEFunction{false}(profitdrift, profitnoise)
prob = SDEProblem(system, 0., (0., 1.)) |> EnsembleProblem

trajectories = 250

solutions = [solve(prob, SOSRI(); p, trajectories) for p in parameters];
ȳ = maximum(maximum(maximum(abs, traj) for traj in sol) for sol in solutions)
summaries = [EnsembleSummary(sol) for sol in solutions]

let 
    n = 20
    alpha = 0.1
    linewidth = 1.5
    c = :black
    xlims = (0, 1)
    ylims = (-ȳ, ȳ)
    
    p11 = plot(; xlabel = nothing, ylabel = L"Pre-Adoption $i = 0$", title = L"Pessimistic $\alpha_{q} = %$(pessimistic.α)$", legend = false,  xlims, ylims)
    for i in 1:n
        plot!(p11, solutions[1, 1][i]; alpha, linewidth, c)
    end

    plot!(p11, summaries[1, 1], c = :black, xlabel = nothing)
    

    p12 = plot(; xlabel = nothing, ylabel = nothing, title = L"Optimistic $\alpha_{q} = %$(optimistic.α)$", legend = false,  xlims, ylims)
    for i in 1:n
        plot!(p12, solutions[1, 2][i]; alpha, linewidth, c)
    end

    plot!(p12, summaries[1, 2], c = :black, xlabel = nothing)
    

    p21 = plot(; xlabel = L"Time $t$", ylabel = L"Post-adoption $i = 1$", title = nothing, legend = false,  xlims, ylims)
    for i in 1:n
        plot!(p21, solutions[2, 1][i]; alpha, linewidth, c)
    end

    plot!(p21, summaries[2, 1], c = :black, xlabel = L"Time $t$")
    

    p22 = plot(; xlabel = L"Time $t$", ylabel = nothing, title = nothing, legend = false,  xlims, ylims)
    for i in 1:n
        plot!(p22, solutions[2, 2][i]; alpha, linewidth, c)
    end

    plot!(p22, summaries[2, 2], c = :black, xlabel = L"Time $t$")
    

    gridLayout = @layout [a b; c d]
    
    gridfig = plot(p11, p12, p21, p22, layout = gridLayout, size = 600 .* (√2, 1), plot_title  = L"Expected growth rate profit $\log\pi_{i, q}(t) / \pi_{i, q}(0)$", top_margin = 2.5Plots.mm, bottom_margin = 0Plots.mm)
    
    savefig(gridfig, joinpath(PLOTPATH, "profitevolution.tikz"))
    
    gridfig
end
