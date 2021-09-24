module Tests
using ..Promises
using Test

@testset "Unresolved Promise" begin
    p = Promise{String}()
    f = p.future
    @test f.state == Promises.FutureStateUnresolved{String}()
    @test !isResolved(f)
    @test !hasResult(f)
    @test !hasError(f)
    @test !isCancelled(f)
end

@testset "Resolved Promises" begin
    p = Promise{String}()
    f = p.future

    setResult(p, "1")
    @test isResolved(f)
    @test hasResult(f)
    @test !hasError(f)
    @test !isCancelled(f)
    @test getResult(f) == "1"
    @test getError(f.state) === nothing
    @test f.state isa Promises.FutureStateResult

    p = Promise{String}()
    f = p.future
    setError(p, ErrorException("TestError"))
    @test isResolved(f)
    @test !hasResult(f)
    @test hasError(f)
    @test !isCancelled(f)
    @test getResult(f) === nothing
    @test getError(f) isa ErrorException

    p = Promise{String}()
    f = p.future
    cancel(p)
    @test isResolved(f)
    @test !hasResult(f)
    @test !hasError(f)
    @test isCancelled(f)
    @test getResult(f) === nothing
    @test f.state isa Promises.FutureStateCancelled

    p = Promise{String}()
    f = p.future
    t = @task setResult(p, "1")
    schedule(t)
    wait(t)
    @test getResult(f) == "1"

    p = Promise{String}()
    f = p.future
    @async setResult(p, "1")
    waitOn(f)
    @test hasResult(f)
    @test getResult(f) == "1"
end

@testset "Futures" begin
    f = futureWithResult(true)
    @test isResolved(f)
    @test hasResult(f)
    @test !hasError(f)
    @test !isCancelled(f)

    f = futureWithError(Bool, ErrorException("TestError"))
    @test isResolved(f)
    @test !hasResult(f)
    @test hasError(f)
    @test !isCancelled(f)
    @test f.state isa Promises.FutureStateError

    f = cancelledFuture(Bool)
    @test isResolved(f)
    @test !hasResult(f)
    @test !hasError(f)
    @test isCancelled(f)

    f = futureWithResult(true)
    f2 = futureWithResolutionOf(f)
    @test isResolved(f2)
    @test hasResult(f2)
    @test !hasError(f2)
    @test !isCancelled(f2)

    f = futureWithError(Bool, ErrorException("TestError"))
    f2 = futureWithResolutionOf(f)
    @test isResolved(f2)
    @test !hasResult(f2)
    @test hasError(f2)
    @test !isCancelled(f2)

    f = cancelledFuture(Bool)
    f2 = futureWithResolutionOf(f)
    @test isResolved(f2)
    @test !hasResult(f2)
    @test !hasError(f2)
    @test isCancelled(f2)
end
end
