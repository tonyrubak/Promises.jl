mutable struct Future{T}
    state::FutureState{T}
    cv::Threads.Condition
end

function Future{T}() where T
    Future{T}(FutureStateUnresolved{T}(), Threads.Condition())
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

function futureWithResolutionOf(f::Future)
    Future(f.state, Threads.Condition())
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
    notify(f.cv)
    unlock(f.cv)
end

function setError(f::Future{T}, error::Exception) where T
    lock(f.cv)
    @assert f.state isa FutureStateUnresolved
    f.state = FutureStateError{T}(error)
    notify(f.cv)
    unlock(f.cv)
end

function cancel(f::Future{T}) where T
    lock(f.cv)
    @assert f.state isa FutureStateUnresolved
    f.state = FutureStateCancelled{T}()
    notify(f.cv)
    unlock(f.cv)
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