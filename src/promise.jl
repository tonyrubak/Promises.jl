export setResult, setError, cancel, setResolution

struct Promise{T}
    future::Future{T}
end

function Promise{T}() where {T}
    Promise{T}(Future{T}())
end  

function setResult(p::Promise, result)
    setResult(p.future, result)
end

function setError(p::Promise, error)
    setError(p.future, error)
end  

function cancel(p::Promise)
    cancel(p.future)
end

function setResolution(p::Promise{T}, of::Future{T}) where T
    if of.state isa FutureStateResult
        setResult(p,of.state.value)
    elseif of.state isa FutureStateError
        setError(p,of.state.error)
    else
        cancel(p)
    end
end