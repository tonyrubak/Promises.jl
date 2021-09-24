module Promises
export Future, Promise
export isResolved, hasResult, hasError
export futureWithResult, futureWithError, cancelledFuture
export futureWithResolutionOf
export setResult, setError, cancel, waitOn
export getResult, getError

abstract type Option{T} end

struct None{T} <: Option{T} end

struct Some{T} <: Option{T}
  value::T
end

include("src/future.jl")
include("src/promise.jl")
include("src/tests.jl")

end # module
