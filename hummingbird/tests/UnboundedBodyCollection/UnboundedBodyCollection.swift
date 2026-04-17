//codeql-extractor-options:-module-name HummingbirdCore
// Test cases for the swift/unbounded-body-collection query.
//
// Lines marked `// $ swift/unbounded-body-collection` are expected to be flagged.
// Lines without the annotation are expected to be clean.
//
// Threshold: 104_857_600 bytes (100 MiB). Values at or above are flagged.

// ── Minimal stub mirroring the HummingbirdCore.Request API ────────────────────

public struct Request {
    public func collectBody(upTo maxSize: Int) async throws -> [UInt8] { [] }
}

// ── BAD: unbounded or excessively large caps ───────────────────────────────────

func badDotMax(request: Request) async throws {
    let _ = try await request.collectBody(upTo: .max) // $ swift/unbounded-body-collection
}

func badIntMax(request: Request) async throws {
    let _ = try await request.collectBody(upTo: Int.max) // $ swift/unbounded-body-collection
}

func badExcessiveLiteral(request: Request) async throws {
    let _ = try await request.collectBody(upTo: 200000000) // $ swift/unbounded-body-collection
}

func badAtThreshold(request: Request) async throws {
    let _ = try await request.collectBody(upTo: 104857600) // $ swift/unbounded-body-collection
}

// ── GOOD: strict, route-appropriate caps ──────────────────────────────────────

func goodOneMib(request: Request) async throws {
    let _ = try await request.collectBody(upTo: 1048576)
}

func goodJustBelowThreshold(request: Request) async throws {
    let _ = try await request.collectBody(upTo: 104857599)
}

func goodTenMib(request: Request) async throws {
    let _ = try await request.collectBody(upTo: 10485760)
}
