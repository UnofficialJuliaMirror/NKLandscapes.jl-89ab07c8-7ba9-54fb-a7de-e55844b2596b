import Base.Random: rand, zeros

export Genotype, contribs, fitness

@doc """A genotype representation.
"""
type Genotype{T <: Landscape}
  alleles::AlleleString
  landscape::T
end

Genotype{T <: Landscape}(alleles::Integer, landscape::T) = Genotype(AlleleString(alleles), landscape)

@doc """contribs(g::Genotype, update::Function)

Return a vector of contributions where the ith element in
the vector is the contribution made by the ith allele in the
genotype, given the values of the k alleles to which it is
epistatically linked.
"""
function contribs(g::Genotype, update::Function)
  return map(1:g.landscape.n) do i
    linksmask::AlleleMask = g.landscape.links[i]
    contribstring::AlleleString = g.alleles & linksmask
    return get!(update, g.landscape.contribs[i], contribstring)
  end
end

@doc """contribs(g::Genotype)
"""
contribs(g::Genotype{NKLandscape}) = contribs(g, () -> rand())

@doc """contribs(g::Genotype)
"""
contribs(g::Genotype{NKqLandscape}) = contribs(g, () -> rand(0:(g.landscape.q - 1)))

@doc """contribs(g::Genotype)
"""
function contribs(g::Genotype{NKpLandscape})
  update = () -> begin
    if rand() <g.landscape.p
      return 0.0
    else
      return rand()
    end
  end
  return contribs(g, update)
end

@doc """fitness(g::Genotype{NKqLandscape})
"""
fitness(g::Genotype{NKqLandscape}) = mean(contribs(g)) / (g.landscape.q - 1)
  # TODO: Do we include the fake NKp zeros in the sum or just let the fitness range lower?

@doc """fitness(g::Genotype)

Compute the fitness of a particular genotype.
"""
fitness(g::Genotype) = mean(contribs(g))

function rand(::Type{Genotype}, ls::Landscape)
  nmask = (AlleleMask(1) << ls.n) - 1
  Genotype(rand(AlleleString) & nmask, ls)
end

zeros(::Type{Genotype}, ls::Landscape) = Genotype(0, ls)
