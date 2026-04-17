// Test cases for the swift/dropped-continuation query.
//
// Lines marked `// $ swift/dropped-continuation` are expected to be flagged.
// Lines without the annotation are expected to be clean.

func someCallbackAPI(completion: @escaping (Int) -> Void) { completion(42) }
func storeAndResumeLater(_ continuation: CheckedContinuation<Int, Never>) {
    continuation.resume(returning: 0)
}
func registerContinuation(_ continuation: CheckedContinuation<Int, Never>) {}
func someCondition() -> Bool { true }

// ── BAD: continuation created but never resumed ───────────────────────────────

func badNeverResumed() async -> Int {
    await withCheckedContinuation { continuation in // $ swift/dropped-continuation
        let _ = continuation
    }
}

func badThrowingNeverResumed() async throws -> Int {
    try await withCheckedThrowingContinuation { continuation in // $ swift/dropped-continuation
        let _ = continuation
    }
}

func badUnsafeNeverResumed() async -> Int {
    await withUnsafeContinuation { continuation in // $ swift/dropped-continuation
        let _ = continuation
    }
}

func badForgetToResume() async -> Int {
    await withCheckedContinuation { continuation in // $ swift/dropped-continuation
        _ = 42
    }
}

// ── GOOD: resumed directly ────────────────────────────────────────────────────

func goodDirectResume() async -> Int {
    await withCheckedContinuation { continuation in
        continuation.resume(returning: 42)
    }
}

// ── GOOD: resumed inside inner closure ───────────────────────────────────────

func goodCallbackResume() async -> Int {
    await withCheckedContinuation { continuation in
        someCallbackAPI { value in
            continuation.resume(returning: value)
        }
    }
}

// ── GOOD: continuation escapes via argument ───────────────────────────────────
// Passing the continuation to another function is the standard async-bridging
// pattern. The callee is responsible for resuming — not a dropped continuation.

func goodPassedAsArgument() async -> Int {
    await withCheckedContinuation { continuation in
        storeAndResumeLater(continuation)
    }
}

func goodPassedAsNamedArgument() async -> Int {
    await withCheckedContinuation { continuation in
        registerContinuation(continuation)
    }
}

// ── GOOD: continuation escapes via assignment ─────────────────────────────────
// Storing the continuation in a field for later resumption is equally valid.

class ContinuationHolder {
    var pending: CheckedContinuation<Int, Never>?

    func wait() async -> Int {
        await withCheckedContinuation { continuation in
            self.pending = continuation
        }
    }
}

// ── KNOWN LIMITATION: only one branch of an if resumes the continuation ───────
// hasResumeInClosure sees the resume call and treats the continuation as handled,
// even though the else path silently drops it. A fix requires path-sensitivity
// (dataflow through all exits of the closure body).

func knownFalseNegativePartialIfResume() async -> Int {
    await withCheckedContinuation { continuation in
        if someCondition() {
            continuation.resume(returning: 1)
            // else: continuation is dropped — not currently detected
        }
    }
}
