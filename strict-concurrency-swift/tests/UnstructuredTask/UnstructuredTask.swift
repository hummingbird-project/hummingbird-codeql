// Test cases for the swift/unstructured-task query.
//
// Lines marked `// $ swift/unstructured-task` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Support declarations ──────────────────────────────────────────────────────

func doWork() async {}
func computeThrowing() async throws -> Int { 42 }

// ── BAD: unstructured task creation ──────────────────────────────────────────

func badBareTask() {
    // The simplest form — no explicit priority.
    Task { // $ swift/unstructured-task
        await doWork()
    }
}

func badTaskWithPriority() {
    // Explicit priority does not change the structural problem.
    Task(priority: .background) { // $ swift/unstructured-task
        await doWork()
    }
}

func badDetachedTask() {
    // detached inherits neither priority nor task-local values.
    Task.detached { // $ swift/unstructured-task
        await doWork()
    }
}

func badDetachedWithPriority() {
    Task.detached(priority: .userInitiated) { // $ swift/unstructured-task
        await doWork()
    }
}

// ── GOOD: structured concurrency ─────────────────────────────────────────────

func goodAsyncLet() async {
    // async let creates a child task that is awaited before the scope exits.
    async let _ = doWork()
}

func goodTaskGroup() async {
    // withTaskGroup automatically cancels and awaits all child tasks on exit.
    await withTaskGroup(of: Void.self) { group in
        group.addTask { await doWork() }
    }
}

func goodThrowingTaskGroup() async throws {
    // withThrowingTaskGroup provides the same structured guarantees with throws.
    _ = try await withThrowingTaskGroup(of: Int.self) { group in
        group.addTask { try await computeThrowing() }
        return try await group.next() ?? 0
    }
}
