mutable struct Future{T}
    state::Symbol
    isCancelled::Bool
    result::Option{T}
    error::Option{Exception}
    cv::Threads.Condition
end

function Future{T}() where T
    Future{T}(:unresolved, false, None{T}(), None{Exception}(), Threads.Condition())
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
    Future(f.state, f.isCancelled, f.result, f.error, Threads.Condition())
end

function isResolved(f::Future{T}) where T
    lock(f.cv)
    retval = f.state != :unresolved
    unlock(f.cv)
    retval
end

function hasResult(f::Future{T}) where T
    lock(f.cv)
    retval = isa(f.result, Some{T})
    unlock(f.cv)
    retval
end

function hasError(f::Future{T}) where T
    lock(f.cv)
    retval = isa(f.error, Some)
    unlock(f.cv)
    retval
end

function setResult(f::Future{T}, result::T) where T
    lock(f.cv)
    @assert f.state == :unresolved
    f.state = :resolved
    f.result = Some{T}(result)
    notify(f.cv)
    unlock(f.cv)
end

function setError(f::Future, error::Exception)
    lock(f.cv)
    @assert f.state == :unresolved
    f.state = :error
    f.error = Some{Exception}(error)
    notify(f.cv)
    unlock(f.cv)
end

function cancel(f::Future)
    lock(f.cv)
    @assert f.state == :unresolved
    f.state = :cancelled
    f.isCancelled = true
    notify(f.cv)
    unlock(f.cv)
end

function waitOn(f::Future)
    lock(f.cv)
    while (f.state == :unresolved)
        wait(f.cv)
    end
    unlock(f.cv)
end

function getResult(f::Future)
    if f.result isa Some
        f.result.value
    else
        nothing
    end
end

function getResultOrWait(f::Future)
    waitOn(f)
    if f.result isa Some
        f.result.value
    else
        nothing
    end
end

function getError(f::Future)
    if f.error isa Some
        f.error.value
    else
        nothing
    end
end

function getErrorOrWait(f::Future)
    waitOn(f)
    if f.error isa Some
        f.error.value
    else
        nothing
    end
end