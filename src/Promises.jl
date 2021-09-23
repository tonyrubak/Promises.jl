module Promises
export Future, Promise
export isResolved, hasResult, hasError
export futureWithResult, futureWithError, cancelledFuture
export futureWithResolutionOf
export setResult, setError, cancel
export getResult

abstract type Option{T} end

struct None{T} <: Option{T} end

struct Some{T} <: Option{T}
  value::T
end

mutable struct Future{T}
  state::Symbol
  isCancelled::Bool
  result::Option{T}
  error::Option{Exception}
end

function Future{T}() where T
  Future{T}(:unresolved, false, None{T}(), None{Exception}())
end

function futureWithResult(result::T) where T
  Future{T}(:resolved, false, Some(result), None{Exception}())
end

function futureWithError(t::Type, error::Exception)
  Future{t}(:resolved, false, None{t}(), Some{Exception}(error))
end

function cancelledFuture(t::Type)
  Future{t}(:resolved, true, None{t}(), None{Exception}())
end

function futureWithResolutionOf(f::Future)
  Future(f.state, f.isCancelled, f.result, f.error)
end

function Future{T}(result, error::String) where T
  Future{T}(:resolved, false, None{T}(), Some(error))
end

function isResolved(f::Future{T}) where T
  f.state != :unresolved
end

function hasResult(f::Future{T}) where T
  isa(f.result, Some{T})
end

function hasError(f::Future{T}) where T
  isa(f.error, Some)
end

function setResult(f::Future{T}, result::T) where T

  @assert f.state == :unresolved


end

function getResult(f::Future)
  f.result.value
end

struct Promise{T}
  future::Future{T}
end

function Promise{T}() where {T}
  Promise{T}(Future{T}())
end

function setResult(p::Promise, result)
  p.future.result = Some(result)
  p.future.state = :resolved
end

function setError(p::Promise, error)
  p.future.error = Some{Exception}(error)
  p.future.state = :resolved
end

function cancel(p::Promise)
  p.future.isCancelled = true
  p.future.state = :cancelled
end

module Tests
using ..Promises
using Test

@testset "Unresolved Promise" begin
  p = Promise{String}()
  f = p.future
  @test f.state == :unresolved
  @test isResolved(f) == false
  @test hasResult(f) == false
  @test hasError(f) == false
  @test f.isCancelled == false
end

@testset "Resolved Promises" begin
  p = Promise{String}()
  f = p.future

  setResult(p,"1")
  @test isResolved(f) == true
  @test hasResult(f) == true
  @test hasError(f) == false
  @test f.isCancelled == false
  @test getResult(f) == "1"
  @test isa(f.error,Promises.None{Exception})
  @test f.state == :resolved

  p = Promise{String}()
  f = p.future
  setError(p,ErrorException("TestError"))
  @test isResolved(f) == true
  @test hasResult(f) == false
  @test hasError(f) == true
  @test f.isCancelled == false
  @test f.result isa Promises.None
  @test f.error isa Promises.Some

  p = Promise{String}()
  f = p.future
  cancel(p)
  @test isResolved(f) == true
  @test hasResult(f) == false
  @test hasError(f) == false
  @test f.isCancelled == true
  @test f.result isa Promises.None
  @test f.result isa Promises.None
  @test f.state == :cancelled

  p = Promise{String}()
  f = p.future
  t = @task begin; setResult(p,"1"); end
  schedule(t)
  wait(t)
  @test f.result == Promises.Some("1")
end

@testset "Futures" begin
  f = futureWithResult(true)
  @test isResolved(f) == true
  @test hasResult(f) == true
  @test hasError(f) == false
  @test f.isCancelled == false

  f = futureWithError(Bool,ErrorException("TestError"))
  @test isResolved(f) == true
  @test hasResult(f) == false
  @test hasError(f) == true
  @test f.isCancelled == false

  f = cancelledFuture(Bool)
  @test isResolved(f) == true
  @test hasResult(f) == false
  @test hasError(f) == false
  @test f.isCancelled == true

  f = futureWithResult(true)
  f2 = futureWithResolutionOf(f)
  @test isResolved(f2) == true
  @test hasResult(f2) == true
  @test hasError(f2) == false
  @test f2.isCancelled == false

  f = futureWithError(Bool,ErrorException("TestError"))
  f2 = futureWithResolutionOf(f)
  @test isResolved(f2) == true
  @test hasResult(f2) == false
  @test hasError(f2) == true
  @test f2.isCancelled == false

  f = cancelledFuture(Bool)
  f2 = futureWithResolutionOf(f)
  @test isResolved(f2) == true
  @test hasResult(f2) == false
  @test hasError(f2) == false
  @test f2.isCancelled == true
end
end

end # module
