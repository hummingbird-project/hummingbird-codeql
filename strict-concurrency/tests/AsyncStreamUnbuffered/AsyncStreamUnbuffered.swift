// Test cases for the swift/async-stream-unbounded-buffer query.
//
// Lines marked `// $ swift/async-stream-unbounded-buffer` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Stubs ─────────────────────────────────────────────────────────────────────

public struct AsyncStream<Element> {
    public struct Continuation {
        public enum BufferingPolicy {
            case unbounded
            case bufferingOldest(Int)
            case bufferingNewest(Int)
        }
    }

    public init(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded,
        _ build: (Continuation) -> Void
    ) { }

    public init(unfolding produce: @escaping () async -> Element?) { }

    public static func makeStream(
        of elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: AsyncStream<Element>, continuation: AsyncStream<Element>.Continuation) {
        fatalError()
    }
}

public struct AsyncThrowingStream<Element, Failure: Error> {
    public struct Continuation {
        public enum BufferingPolicy {
            case unbounded
            case bufferingOldest(Int)
            case bufferingNewest(Int)
        }
    }

    public init(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded,
        _ build: (Continuation) -> Void
    ) { }

    public static func makeStream(
        of elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: AsyncThrowingStream<Element, Failure>, continuation: AsyncThrowingStream<Element, Failure>.Continuation) {
        fatalError()
    }
}

// ── BAD: default (unbounded) buffer ───────────────────────────────────────────

func badUnboundedInt() -> AsyncStream<Int> {
    AsyncStream<Int> { continuation in // $ swift/async-stream-unbounded-buffer
        // fast producer
    }
}

func badUnboundedString() -> AsyncStream<String> {
    AsyncStream(String.self) { continuation in // $ swift/async-stream-unbounded-buffer
        // fast producer
    }
}

// ── GOOD: explicit bounded policy ─────────────────────────────────────────────

func goodNewest() -> AsyncStream<Int> {
    AsyncStream<Int>(bufferingPolicy: .bufferingNewest(100)) { _ in }
}

func goodOldest() -> AsyncStream<String> {
    AsyncStream(String.self, bufferingPolicy: .bufferingOldest(50)) { _ in }
}

// ── GOOD: explicit .unbounded — deliberate choice, not flagged ────────────────

func goodExplicitUnbounded() -> AsyncStream<Int> {
    AsyncStream<Int>(bufferingPolicy: .unbounded) { _ in }
}

// ── BAD: makeStream without bufferingPolicy ───────────────────────────────────

func badMakeStream() {
    let (_, _) = AsyncStream.makeStream(of: Int.self) // $ swift/async-stream-unbounded-buffer
}

func badThrowingMakeStream() {
    let (_, _) = AsyncThrowingStream.makeStream(of: Int.self) // $ swift/async-stream-unbounded-buffer
}

// ── BAD: AsyncThrowingStream closure init without bufferingPolicy ─────────────

func badThrowingStream() -> AsyncThrowingStream<Int, Error> {
    AsyncThrowingStream<Int, Error> { continuation in // $ swift/async-stream-unbounded-buffer
        // fast producer
    }
}

// ── GOOD: makeStream with explicit bounded policy ─────────────────────────────

func goodMakeStreamBounded() {
    let (_, _) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .bufferingNewest(100))
}

func goodThrowingMakeStreamBounded() {
    let (_, _) = AsyncThrowingStream.makeStream(of: String.self, bufferingPolicy: .bufferingOldest(50))
}

// ── GOOD: pull-model (unfolding:) — no buffering policy ───────────────────────

func goodUnfolding() -> AsyncStream<Int> {
    AsyncStream(unfolding: { 42 })
}
