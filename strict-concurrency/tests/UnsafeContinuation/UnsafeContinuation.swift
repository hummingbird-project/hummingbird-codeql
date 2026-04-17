// Test cases for the swift/unsafe-continuation query.
//
// Lines marked `// $ swift/unsafe-continuation` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── BAD: unsafe continuations ────────────────────────────────────────────────

func badUnsafeContinuation() async -> Int {
    await withUnsafeContinuation { continuation in // $ swift/unsafe-continuation
        continuation.resume(returning: 42)
    }
}

func badUnsafeThrowingContinuation() async throws -> Int {
    try await withUnsafeThrowingContinuation { continuation in // $ swift/unsafe-continuation
        continuation.resume(returning: 42)
    }
}

// ── GOOD: checked continuations ──────────────────────────────────────────────

func goodCheckedContinuation() async -> Int {
    await withCheckedContinuation { continuation in
        continuation.resume(returning: 42)
    }
}

func goodCheckedThrowingContinuation() async throws -> Int {
    try await withCheckedThrowingContinuation { continuation in
        continuation.resume(returning: 42)
    }
}
