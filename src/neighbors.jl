export number_neighbors, all_neighbors, random_neighbor,
    neutral_neighbors, fitter_neighbors, fitness_range_neighbors,
    fittest_neighbors, fittest_neighbor

@doc """neighbors(g::Genotype)

Returns a list of neighbors of Genotype g.
"""
# TODO: Implement all four of Nowak and Krug's methods.

function neighbors(g::Genotype)
  result = Genotype[]
  for i = 0:(g.landscape.n - 1)
    locusmask = AlleleMask(1) << i
    alleles::AlleleString = xor(g.alleles, locusmask)
    Base.push!(result,Genotype(alleles, g.landscape))
  end
  result
end

@doc """number_neighbors(g::Genotype)

Returns the number of one-mutant neighbors of a genotype.
"""
function number_neighbors(g::Genotype)
  (g.landscape.a - 1) * g.landscape.n
end

@doc """all_neighbors(g::Genotype)

Returns a vector that contains all neighbors of the given `Genotype`.
"""
function all_neighbors(g::Genotype; sorted::Bool=true)
  genotypes = map(neighbors(g)) do gt
    return gt
  end
  return if sorted
    sort!(genotypes, by=(g) -> fitness(g))
  else
    genotypes
  end
end

@doc """random_neighbor(g::Genotype)

Returns a random neighbor of the given genotype.
"""
function random_neighbor(g::Genotype)
  i = rand(0:(g.landscape.n - 1))
  locusmask = AlleleMask(1) << i
  alleles::AlleleString = xor(g.alleles, locusmask)
  return Genotype(alleles, g.landscape)
end

@doc """neutral_neighbors(g::Genotype)

Returns a vector of genotypes with fitness approximately equal to the given
genotype.
"""
function neutral_neighbors(g::Genotype)
  f0 = fitness(g)
  return filter(neighbors(g)) do gt
    isapprox(fitness(gt), f0)
  end |> collect
end

@doc """fitter_neighbors(g::Genotype; sorted::Bool=true, orequal::Bool=false)

Returns a vector of genotypes with fitness greater than the given genotype. If
`sorted` is `true`, the genotypes returned will be sorted from lowest fitness
to highest fitness. If `orequal` is `true` (the default is `false`), then
genotypes of approximately equal fitness will be included.
"""
function fitter_neighbors(g::Genotype; sorted::Bool=true, orequal::Bool=false)
  f0 = fitness(g)
  if !orequal
    genotypes = filter(neighbors(g)) do gt
      fitness(gt) > f0
    end |> collect
  else
    genotypes = filter(neighbors(g)) do gt
      fitness(gt) >= f0
    end |> collect
  end
  return if sorted
    sort!(genotypes, by=(g) -> fitness(g))
  else
    genotypes
  end
end

@doc """fitness_range_neighbors(g::Genotype, lb::Float64, ub::Float64; sorted::Bool=true)

Returns all neighbors with fitness in the half open interval [lb, ub) as
columns of a matrix, sorted from lowest fitness (left) to highest fitness
(right).
"""
function fitness_range_neighbors(g::Genotype, lb::Float64, ub::Float64; sorted::Bool=true)
  genotypes = filter(neighbors(g)) do gt
    lb <= fitness(gt) < ub
  end |> collect
  return if sorted
    sort!(genotypes, by=(g) -> fitness(g))
  else
    genotypes
  end
end

@doc """fittest_neighbors(g::Genotype, count::Int64; sorted::Bool=true)

Returns the fittest neighbors, some of which might be less fit than the given
genotype, sorted from lowest fitness to highest fitness.
"""
function fittest_neighbors(g::Genotype, count::Int64)
  @assert count > 0
  @assert count <= number_neighbors(g)

  return all_neighbors(g)[(end - count + 1):end]
end

@doc """fittest_neighbor(g::Genotype)

Returns the single fittest neighbor, even if it is less fit than the given
genotype.
"""
function fittest_neighbor(g::Genotype)
  return all_neighbors(g)[end]
end

