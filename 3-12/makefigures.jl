using Plots, PGFPlotsX
using LaTeXStrings
using UnPack

using DifferentialEquations

default(linewidth = 3, background = :transparent)
theme(:wong2)
pgfplotsx()

PLOTPATH = "3-12/figures"

## Plotting Utils
Nspace = range(0, 5, 1001)

struct Technology{S}
    a::S
    b::S
end

## Profit function
function profit(N, technology::Technology)
    @unpack a, b = technology
    return a * N^b
end

existing = Technology(1., 0.75)
adapted = Technology(1.1, 0.5)

let
    profitfig = plot(xlabel = L"Resource pool $N(t)$", ylabel = L"Profits $\pi(t)$", legend_title = L"i", size = 200 .* (16 / 9, 1))

    plot!(profitfig, Nspace, N -> profit(N, existing), label = L"0")
    plot!(profitfig, Nspace, N -> profit(N, adapted), label = L"1")

    savefig(profitfig, joinpath(PLOTPATH, "profit.tikz"))

    profitfig
end


## Profit dynamics
struct Beliefs{S}
    α::S
    σ::S
end

optimistic = Beliefs(-0.05, 1.)
pessimistic = Beliefs(-0.5, 1.)

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

