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

    setResult(p, "1")
    @test isResolved(f) == true
    @test hasResult(f) == true
    @test hasError(f) == false
    @test f.isCancelled == false
    @test getResult(f) == "1"
    @test isa(f.error, Promises.None{Exception})
    @test f.state == :resolved

    p = Promise{String}()
    f = p.future
    setError(p, ErrorException("TestError"))
    @test isResolved(f) == true
    @test hasResult(f) == false
    @test hasError(f) == true
    @test f.isCancelled == false
    @test getResult(f) isa Nothing
    @test getError(f) isa ErrorException

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
    t = @task setResult(p, "1")
    schedule(t)
    wait(t)
    @test f.result == Promises.Some{String}("1")

    p = Promise{String}()
    f = p.future
    @async setResult(p, "1")
    waitOn(f)
    @test hasResult(f) == true
    @test f.result == Promises.Some{String}("1")
end

@testset "Futures" begin
    f = futureWithResult(true)
    @test isResolved(f) == true
    @test hasResult(f) == true
    @test hasError(f) == false
    @test f.isCancelled == false

    f = futureWithError(Bool, ErrorException("TestError"))
    @test isResolved(f) == true
    @test hasResult(f) == false
    @test hasError(f) == true
    @test f.isCancelled == false
    @test f.state == :error

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

    f = futureWithError(Bool, ErrorException("TestError"))
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
