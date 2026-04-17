// Test cases for the swift/multiple-continuation-resumes query.
//
// Lines marked `// $ swift/multiple-continuation-resumes` are expected to be flagged.
// Lines without the annotation are expected to be clean.

func someCallbackAPI(completion: @escaping (Int) -> Void) { completion(42) }
func storeForLater(_ continuation: CheckedContinuation<Int, Never>) {}
func someCondition() -> Bool { true }

enum SomeAction { case doItNow(Int), deferResume }
func computeAction(_ cont: CheckedContinuation<Int, Never>) -> SomeAction { .doItNow(42) }

// ── BAD: multiple resume calls, both unconditionally reachable ────────────────

func badSequentialResumes() async -> Int {
    await withCheckedContinuation { continuation in // $ swift/multiple-continuation-resumes
        continuation.resume(returning: 1)
        continuation.resume(returning: 2)
    }
}

func badSequentialThrowingResumes() async throws -> Int {
    try await withCheckedThrowingContinuation { continuation in // $ swift/multiple-continuation-resumes
        continuation.resume(returning: 1)
        continuation.resume(returning: 2)
    }
}

func badSequentialUnsafeResumes() async -> Int {
    await withUnsafeContinuation { continuation in // $ swift/multiple-continuation-resumes
        continuation.resume(returning: 1)
        continuation.resume(returning: 2)
    }
}

// ── GOOD: single resume per execution path ────────────────────────────────────

func goodSingleResume() async -> Int {
    await withCheckedContinuation { continuation in
        continuation.resume(returning: 42)
    }
}

func goodCallbackResume() async -> Int {
    await withCheckedContinuation { continuation in
        someCallbackAPI { value in
            continuation.resume(returning: value)
        }
    }
}

// ── GOOD: continuation escapes — state machine manages resume ─────────────────
// When the continuation is passed to an external function, the state machine
// owns the resume. Multiple resume call sites inside the closure are just
// mutually exclusive dispatch branches — only one fires per execution.
// This is the pattern used in Transaction, NIOAsyncWriter, etc.

func goodStateMachineWithInlineFastPath() async -> Int {
    await withCheckedContinuation { continuation in
        let action = computeAction(continuation)  // continuation escapes as argument
        switch action {
        case .doItNow(let value):
            continuation.resume(returning: value)  // fast path: resume inline
        case .deferResume:
            break  // slow path: state machine resumes later
        }
    }
}

func goodStoredContinuation() async -> Int {
    await withCheckedContinuation { continuation in
        storeForLater(continuation)  // continuation escapes; resumed by holder
    }
}

// ── GOOD: mutually exclusive branches (if/else, switch, guard) ────────────────
// Each execution path resumes the continuation exactly once.

func goodIfElseResume() async -> Int {
    await withCheckedContinuation { continuation in
        if someCondition() {
            continuation.resume(returning: 1)
        } else {
            continuation.resume(returning: 2)
        }
    }
}

func goodSwitchCaseResume() async -> Int {
    await withCheckedContinuation { continuation in
        switch someCondition() {
        case true:
            continuation.resume(returning: 1)
        case false:
            continuation.resume(returning: 2)
        }
    }
}

func goodGuardResume() async -> Int {
    await withCheckedContinuation { continuation in
        guard someCondition() else {
            continuation.resume(returning: 0)
            return
        }
        continuation.resume(returning: 1)
    }
}
