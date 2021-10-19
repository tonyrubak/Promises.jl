export futureWithResult, futureWithError, cancelledFuture
export futureWithResolutionOf
export isResolved, hasResult, hasError
export getResult, getError, isCancelled, getResultOrWait, waitOn
export eventually, then, thenWithResult, onError, whenAll
export eventuallyAsync, thenAsync
export @asyncfn, @future

mutable struct Future{T}
    state::FutureState{T}
    cv::Threads.Condition
    continuation
end

function Future{T}() where T
    Future{T}(FutureStateUnresolved{T}(), Threads.Condition(), nothing)
end

function futureWithResult(result::T) where T
    p = Promise{T}()
    setResult(p, result)
    p.future
end

function futureWithError(t::Type, error::Exception)
    p = Promise{t}()
    setError(p, error)
    p.future
end

function cancelledFuture(t::Type)
    p = Promise{t}()
    cancel(p)
    p.future
end

function futureWithResolutionOf(f::Future{T}) where T
    state = if f.state isa FutureStateResult{T}
        state = FutureStateResult{T}(getResult(f.state))
    elseif f.state isa FutureStateError{T}
        state = FutureStateError{T}(getError(f.state))
    else
        state = FutureStateCancelled{T}()
    end
    Future(state, Threads.Condition(), nothing)
end

function isResolved(f::Future)
    lock(f.cv)
    retval = !(f.state isa FutureStateUnresolved)
    unlock(f.cv)
    retval
end

function hasResult(f::Future)
    lock(f.cv)
    retval = getResult(f.state) !== nothing
    unlock(f.cv)
    retval
end

function hasError(f::Future)
    lock(f.cv)
    retval = getError(f.state) !== nothing
    unlock(f.cv)
    retval
end

function setResult(f::Future{T}, result::T) where T
    lock(f.cv)
    @assert f.state isa FutureStateUnresolved
    f.state = FutureStateResult{T}(result)
    cont = f.continuation
    notify(f.cv)
    unlock(f.cv)
    if cont !== nothing
        cont(f)
    end
end

function setError(f::Future{T}, error::Exception) where T
    lock(f.cv)
    @assert f.state isa FutureStateUnresolved
    f.state = FutureStateError{T}(error)
    cont = f.continuation
    notify(f.cv)
    unlock(f.cv)
    if cont !== nothing
        cont(f)
    end
end

function cancel(f::Future{T}) where T
    lock(f.cv)
    @assert f.state isa FutureStateUnresolved
    f.state = FutureStateCancelled{T}()
    cont = f.continuation
    notify(f.cv)
    unlock(f.cv)
    if cont !== nothing
        cont(f)
    end
end

function waitOn(f::Future)
    lock(f.cv)
    while (f.state isa FutureStateUnresolved)
        wait(f.cv)
    end
    unlock(f.cv)
end

function getResult(f::Future)
    getResult(f.state)
end

function getResultOrWait(f::Future)
    waitOn(f)
    getResult(f.state)
end

function getError(f::Future)
    getError(f.state)
end

function getErrorOrWait(f::Future)
    waitOn(f)
    getError(f.state)
end

function isCancelled(f::Future)
    isCancelled(f.state)
end

function isCancelledOrWait(f::Future)
    waitOn(f)
    isCancelled(f)
end

function eventually(f::Future, continuation)
    setContinuation(f, future -> continuation(future))
end

function eventuallyAsync(f::Future, continuation)
    setContinuation(f, future -> @async continuation(future))
end

function setContinuation(f::Future, continuation)
    lock(f.cv)
    if f.continuation !== nothing
        unlock(f.cv)
        throw(ArgumentError("Continuation Already Set"))
    end
    
    f.continuation = continuation
    resolved = isResolved(f)
    
    unlock(f.cv)
    if (resolved)
        f.continuation(f)
    end
end

function then(f::Future, task, nextResultType::Type)
    promise = Promise{nextResultType}()
    eventually(f, future -> begin
        f2 = task(future)
        eventually(f2, fut2 -> setResolution(promise, fut2))
    end)
    promise.future
end

function thenAsync(f::Future, task, nextResultType::Type)
    promise = Promise{nextResultType}()
    eventuallyAsync(f, future -> begin
        f2 = task(future)
        eventuallyAsync(f2, fut2 -> begin
            setResolution(promise, fut2)
        end)
    end)
    promise.future
end

function thenWithResult(f::Future, task, nextResultType::Type)
    promise = Promise{nextResultType}()
    eventually(f, future -> begin
        if !(future.state isa FutureStateResult)
            setResolution(promise, future)
        else
            f2 = task(future.state.value)
            eventually(f2, fut2 -> begin
                setResolution(promise, fut2)
            end)
        end
    end)
    promise.future
end

function onError(f::Future{T}, continuation) where T
    promise = Promise{T}()
    eventually(f, future -> begin
        if future.state isa FutureStateError
            continuation(getError(future))
        end
        setResolution(promise, future)
    end)
    promise.future
end

function whenAll(futures::Vector{Future{T}}) where T
    promise = Promise{Vector{Future{T}}}()
    counter = Threads.Atomic{Int}(length(futures))
    for element in futures
        eventually(element, future -> begin
            Threads.atomic_sub!(counter,1)
            if (counter[] == 0)
                setResult(promise, futures)
            end
        end)
    end
    promise.future
end

macro asyncfn(expr)
    thunk = esc(:(()->($expr)))
    quote
        p = Promise{Any}()
        fut = p.future
        @async begin
            try
                setResult(fut, $thunk())
            catch ex
                setError(fut, ex)
            end
        end
        fut
    end
end

macro future(expr)
    letargs = Base._lift_one_interp!(expr)

    thunk = esc(:(()->($expr)))
    quote
        p = Promise{Any}()
        fut = p.future
        let $(letargs...)
            @async begin
                try
                    setResult(fut, $thunk())
                catch ex
                    setError(fut, ex)
                end
            end
        end
        fut
    end
end