module Promises
export Future, Promise
export isResolved, hasResult, hasError
export futureWithResult, futureWithError, cancelledFuture
export futureWithResolutionOf
export setResult, setError, cancel, waitOn
export getResult, getError, isCancelled

include("src/futurestate.jl")
include("src/future.jl")
include("src/promise.jl")
include("src/tests.jl")

end # module
