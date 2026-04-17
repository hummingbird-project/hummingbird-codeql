// Test cases for the swift/immediate-continuation-resume query.
//
// Lines marked `// $ swift/immediate-continuation-resume` are expected to be flagged.
// Lines without the annotation are expected to be clean.

func someCallbackAPI(completion: @escaping (Int) -> Void) { completion(42) }
func someThrowingCallbackAPI(completion: @escaping (Result<Int, Error>) -> Void) { completion(.success(42)) }

// ── BAD: immediate resume — no callback is bridged ───────────────────────────

func badCheckedImmediateResume() async -> Int {
    await withCheckedContinuation { continuation in // $ swift/immediate-continuation-resume
        continuation.resume(returning: 42)
    }
}

func badCheckedThrowingImmediateResume() async throws -> Int {
    try await withCheckedThrowingContinuation { continuation in // $ swift/immediate-continuation-resume
        continuation.resume(returning: 42)
    }
}

func badUnsafeImmediateResume() async -> Int {
    await withUnsafeContinuation { continuation in // $ swift/immediate-continuation-resume
        continuation.resume(returning: 42)
    }
}

func badUnsafeThrowingImmediateResume() async throws -> Int {
    try await withUnsafeThrowingContinuation { continuation in // $ swift/immediate-continuation-resume
        continuation.resume(returning: 42)
    }
}

// ── GOOD: closure bridges a callback-based API ────────────────────────────────

func goodBridgedContinuation() async -> Int {
    await withCheckedContinuation { continuation in
        someCallbackAPI { value in
            continuation.resume(returning: value)
        }
    }
}

func goodBridgedThrowingContinuation() async throws -> Int {
    try await withCheckedThrowingContinuation { continuation in
        someThrowingCallbackAPI { result in
            continuation.resume(with: result)
        }
    }
}
