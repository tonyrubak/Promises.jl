module Tests
using ..Promises
using Lazy, Test

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

@testset "Continuations" begin
    p = Promise{String}()
    f = p.future

    eventually(f, future -> @test getResult(f) == "1")
    setResult(p,"1")
    waitOn(f)

    p = Promise{String}()
    f = p.future
    
    eventuallyAsync(f, future -> begin
        @test getResult(f) == "1"
    end)
        
    setResult(p, "1")

    p = Promise{String}()
    f = p.future
        
    f2 = then(f,future -> begin
                p = Promise{String}()
                setResult(p,getResult(future) * "2")
                return p.future
            end, String)
        
    setResult(p,"1")
    @test hasResult(f2)
    @test getResult(f2) == "12"

    p = Promise{String}()
    f = p.future
    
    f2 = then(f, future -> begin
        p = Promise{String}()
        @async setResult(p, getResult(future) * "2")
        p.future
    end, String)
    
    setResult(p, "1")
    waitOn(f2)
    @test hasResult(f2)
    @test getResult(f2) == "12"

    p = Promise{String}()
    f = p.future

    f2 = then(f, future -> begin
        @test hasResult(future)
        futureWithResolutionOf(future)
    end, String)

    setResult(p, "42")
    @test hasResult(f2)
    @test getResult(f2) == "42"

    p = Promise{String}()
    f = p.future

    f2 = then(f, future -> begin
        @test hasError(future)
        futureWithResolutionOf(future)
    end, String)

    setError(p, ErrorException("Test Error"))
    @test hasError(f2)
    @test getError(f2) isa ErrorException

    p = Promise{String}()
    f = p.future

    f2 = then(f, future -> begin
        @test isCancelled(future)
        futureWithResolutionOf(future)
    end, String)

    cancel(p)
    @test isCancelled(f2)

    p = Promise{String}()
    f = p.future
        
    f2 = thenAsync(f, future -> begin
        p = Promise{String}()
        setResult(p, getResult(future) * "2")
        p.future
    end, String)
    
    setResult(p, "1")
    waitOn(f2)
    @test hasResult(f2)
    @test getResult(f2) == "12"

    p = Promise{String}()
    f = p.future

    f2 = thenWithResult(f, val -> begin
        p = Promise{String}()
        setResult(p, val * "2")
        p.future
    end, String)

    setResult(p, "1")
    @test hasResult(f2)
    @test getResult(f2) == "12"

    p = Promise{String}()
    f = p.future

    f2 = thenWithResult(f, value -> begin
        p = Promise{String}()
        setResult(p, val * "2")
        p.future
    end, String)

    setError(p, ErrorException("Test Error"))
    @test hasError(f2)
    @test getError(f2) isa ErrorException

    p = Promise{String}()
    f = p.future

    f2 = thenWithResult(f, future -> begin
        @assert false
        p = Promise{String}()
        setResult(p, val * "2")
        p.future
    end, String)

    cancel(p)
    @test isCancelled(f2)

    p = Promise{String}()
    f = p.future

    f2 = @> f begin
        onError(err -> @assert false)
        then(future -> futureWithResolutionOf(future), String)
    end

    setResult(p, "1")
    @test hasResult(f2)
    @test getResult(f2) == "1"

    p = Promise{String}()
    f = p.future
    
    f2 = @> f begin
        onError(err -> @test true)
        then(future -> begin
            @test true
            futureWithResolutionOf(future)
        end, String)
    end
    
    setError(p, ErrorException("Test Error"))
    @test hasError(f2)
    @test getError(f2) isa ErrorException

    p = Promise{String}()
    f = p.future
    
    f2 = @> f begin
        onError(err -> @assert false)
    end

    cancel(p)
    @test isCancelled(f2)
    @test getResult(f2) === nothing
end

@testset "When All" begin
    p1 = Promise{String}()
    p2 = Promise{String}()
    p3 = Promise{String}()
    
    futures = [p1.future, p2.future, p3.future]
    allFuture = whenAll(futures)
    
    @test !hasResult(allFuture)
    setResult(p3, "3")
    @test !hasResult(allFuture)
    setResult(p2, "2")
    @test !hasResult(allFuture)
    setResult(p1, "1")
    @test hasResult(allFuture)
        
    results = getResult(allFuture)
    @test getResult(results[1]) ==  "1"
    @test getResult(results[2]) ==  "2"
    @test getResult(results[3]) ==  "3"
end

@testset "@asyncfn" begin
    f(x) = @asyncfn begin
        if x > 1
            x + 1
        else
            throw(ErrorException("Not Defined"))
        end
    end

    fut1 = f(2)
    waitOn(fut1)
    @test hasResult(fut1)
    @test getResult(fut1) == 3

    fut2 = f(0)
    waitOn(fut2)
    @test hasError(fut2)
    @test getResult(fut2) === nothing
end

@testset "@future" begin
    x = 2
    fut1 = @future begin
        if $x > 1
            $x + 1
        else
            throw(ErrorException("Not Defined"))
        end
    end

    waitOn(fut1)
    @test hasResult(fut1)
    @test getResult(fut1) == 3

    x = 0
    fut2 = @future begin
        if $x > 1
            $x + 1
        else
            throw(ErrorException("Not Defined"))
        end
    end
    waitOn(fut2)
    @test hasError(fut2)
    @test getResult(fut2) === nothing

    x = 0
    fut3 = @future begin
        sleep(2)
        if x > 1
            x + 1
        else
            throw(ErrorException("Not Defined"))
        end
    end
    x = 2
    waitOn(fut3)
    @test hasResult(fut3)
    @test getResult(fut3) == 3

    x = 0
    fut4 = @future begin
        sleep(2)
        if $x > 1
            $x + 1
        else
            throw(ErrorException("Not Defined"))
        end
    end
    x = 2
    waitOn(fut4)
    @test hasError(fut4)
    @test getResult(fut4) === nothing

end
end
