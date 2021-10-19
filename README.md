A simple and easy-to-use Promises and Futures library for Julia.

# Overview
Promises.jl is based on the work in [Promis](https://github.com/albertodebortoli/Promis).
The library includes two types:
1. Promise - Pass a promise to a function with the expectation that the
promise will be fulfilled in the future.
2. Future - Holds state of a promise or returned directly as a placeholder for
data that will be completed in the future.

The library also includes two macros:
1. @asyncfn - Declare a function that will be executed asynchronously and have
its result returned via a future.
2. @future - Run a code block asynchronously with the result returned via a future.
Similar to @async, but the return value is a future instead of a Task. @future
also supports variable interpolation from the calling environment via $.

The library supports chaining of futures with:
1. eventually
2. then
3. thenWithResult
4. onError
and async variants.

# Usage
```julia
getData(url) = @asyncfn begin
    data = apiCall(url)
    data
end

parsedData = @> getData("url") begin
    thenWithResult(parseData)
    onError(handleError)
end
```