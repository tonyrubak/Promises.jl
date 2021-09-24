import Base.:(==)

abstract type FutureState{T} end

struct FutureStateUnresolved{T} <: FutureState{T} end
struct FutureStateResult{T} <: FutureState{T} value::T end
struct FutureStateError{T} <: FutureState{T} error::Exception end
struct FutureStateCancelled{T} <: FutureState{T} end

function getResult(::FutureState)
    nothing
end

function getResult(state::FutureStateResult)
    state.value
end

function getError(::FutureState)
    nothing
end

function getError(state::FutureStateError)
    state.error
end

function isCancelled(::FutureState)
    false
end

function isCancelled(::FutureStateCancelled)
    true
end

function ==(lhs::FutureState{T}, rhs::FutureState{T}) where T
    if (lhs isa FutureStateCancelled) && (rhs isa FutureStateCancelled)
        true
    elseif (lhs isa FutureStateError) && (rhs isa FutureStateError)
        true
    elseif (lhs isa FutureStateUnresolved) && (rhs isa FutureStateUnresolved)
        true
    elseif (lhs isa FutureStateResult) && (rhs isa FutureStateResult)
        true
    else
        false
    end
end

function !=(lhs::FutureState{T}, rhs::FutureState{T}) where T
    !(lhs == rhs)
end