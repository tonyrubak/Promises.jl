module Promises
export Future, Promise
export isResolved, hasResult, hasError
export futureWithResult, futureWithError, cancelledFuture
export futureWithResolutionOf
export setResult, setError, cancel, waitOn
export getResult, getError, isCancelled, getResultOrWait

include("futurestate.jl")
include("future.jl")
include("promise.jl")
include("tests.jl")

end # module
