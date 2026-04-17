//codeql-extractor-options:-module-name NIOCore
// Test cases for the swift/nio-eventloop-future-wait query.
//
// Lines marked `// $ swift/nio-eventloop-future-wait` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Stubs mirroring SwiftNIO's EventLoopFuture API ───────────────────────────

public struct EventLoopFuture<Value> {
    public func wait() throws -> Value { fatalError() }
}

public struct EventLoopPromise<Value> {
    public var futureResult: EventLoopFuture<Value> { fatalError() }
}

// ── BAD: blocking wait on a future ───────────────────────────────────────────

func badWaitOnFuture(future: EventLoopFuture<String>) throws {
    let _ = try future.wait() // $ swift/nio-eventloop-future-wait
}

func badWaitDiscardResult(future: EventLoopFuture<Void>) throws {
    try future.wait() // $ swift/nio-eventloop-future-wait
}

func badWaitInsideLoop(futures: [EventLoopFuture<Int>]) throws {
    for future in futures {
        let _ = try future.wait() // $ swift/nio-eventloop-future-wait
    }
}

func badWaitOnPromiseFuture(promise: EventLoopPromise<String>) throws {
    let _ = try promise.futureResult.wait() // $ swift/nio-eventloop-future-wait
}

// ── GOOD: async handling without wait ─────────────────────────────────────────

func goodAsyncContext(future: EventLoopFuture<String>) {
    // No wait() — caller uses NIOAsyncChannel and awaits results via structured concurrency.
    _ = future
}
