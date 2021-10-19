module Promises
export Future, Promise

include("futurestate.jl")
include("future.jl")
include("promise.jl")
include("tests.jl")

end # module
