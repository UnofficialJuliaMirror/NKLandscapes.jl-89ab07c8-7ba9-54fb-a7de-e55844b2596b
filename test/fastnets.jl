# To run standalone from NKLandscapes.jl directory:  
#  julia -L "src/NKLandscapes.jl" test/fastnets.jl
import NKLandscapes
const NK = NKLandscapes
using FactCheck

n = 4    # n is arbitrary as long as n >= 3, but larger n may give a better test
k = 0    # k must be 0 for these tests to work
q = 2    # q is the number of possible values for a contrib in NKq landscapes
a = 2    # Only a = 2 is implemented at this time

# Since k == 0, ls has a single minimum fitness neutral net and a single
# maximum fitness neutral net. Works for either an NKq landscape or an NK
# landscape
type LandscapeProperties
  ls::NK.Landscape
  fa::Array{Float64,1}   # Array of fitnesses indexed by integer genotypes
  fl::Array{Int64,1}     # Array of fitness levels indexed by integer genotypes
  min_g::NK.Genotype # A genotype of minimum fitness
end

function LandscapeProperties(ls::NK.Landscape)
  fa = NK.lsfits(ls)
  fl = NK.fitlevs(ls, ls.n, fa)
  min_g = NK.Genotype(indmin(fa) - 1, ls)
  LandscapeProperties(ls, fa, fl, min_g)
end

lsp_nk = LandscapeProperties(NK.NKLandscape(n, k))
lsp_nkq = LandscapeProperties(NK.NKqLandscape(n, k, q))
lsp_list = [lsp_nk, lsp_nkq ]

context("Fast neighbors, walks, and neutral net tests") do
  context("NK.neighbors(...)") do
    for lsp in lsp_list
      fe_length = length(NK.fitter_neighbors(lsp.min_g,orequal=true))
      #println("fe_length:",fe_length)
      @fact n --> fe_length "Expected number of fitter or equal neighbors to be N = $n"
      nn_length = length(NK.neutral_neighbors(lsp.min_g))
      fn_length = length(NK.fitter_neighbors(lsp.min_g))
      @fact n --> nn_length + fn_length "Expected number of neutral nbrs + number of fitter nbrs to be N = $n"
      fit_increment = 1.0/lsp.ls.n - eps()
      lb = 0.0
      frn_sum = 0
      for i = 0:lsp.ls.n
        ub = lb + fit_increment
        frn_length = length(NK.fitness_range_neighbors(lsp.min_g,lb,ub))
        frn_sum += frn_length
        lb = ub 
      end
      @fact n --> frn_sum "Expected sum of number of fitness range neighbors to be N = $n"
    end
  end

  context("NK.walks(...)") do
    for lsp in lsp_list
      max_fit = maximum(lsp.fa)
      rand_w = NK.random_adaptive_walk(lsp.min_g)
      @fact max_fit --> roughly(NK.fitness(rand_w.history_list[end]))
        "Expected final fitness of random adaptive walk to be maximum fitness of landscape which is $max_fit"
      greedy_w = NK.greedy_adaptive_walk(lsp.min_g)
      @fact max_fit --> roughly(NK.fitness(greedy_w.history_list[end]))
        "Expected final fitness of greedy adaptive walk to be maximum fitness of landscape which is $max_fit"
      reluct_w = NK.reluctant_adaptive_walk(lsp.min_g)
      @fact max_fit --> roughly(NK.fitness(reluct_w.history_list[end]))
        "Expected final fitness of reluctant adaptive walk to be maximum fitness of landscape which is $max_fit"
      fit_neutral_w = NK.fitter_then_neutral_walk(lsp.min_g)
      @fact max_fit --> roughly(NK.fitness(fit_neutral_w.history_list[end]))
        "Expected final fitness of fitter_then_neutral adaptive walk to be maximum fitness of landscape which is $max_fit"
    end
  end

  context("NK.netcounts(...)") do
    for lsp in lsp_list
      dsets = NK.neutralnets(lsp.ls, lsp.fl)
      lnn = NK.netcounts(dsets, lsp.fl)
      sort!(lnn, by=x -> x[3])
      if length(lnn) > 1
        @fact lnn[end][3] --> greater_than(lnn[end-1][3])  "Expected a single neutral net of maximum fitness"
      else  # All genotypes have the same fitness
        @fact lsp.ls.a^lsp.ls.n --> lnn[end][2]  "Expected a single neutral net with all genotypes"
      end
    end
  end
end

