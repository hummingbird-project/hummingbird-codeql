//codeql-extractor-options:-module-name HummingbirdCore
// Test cases for the swift/middleware-request-not-forwarded query.
//
// Lines marked `// $ swift/middleware-request-not-forwarded` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Minimal stubs mirroring the Hummingbird API ───────────────────────────────

public struct Request {
    public var headers: [String: String]
    public var uri: String

    public init(headers: [String: String] = [:], uri: String = "/") {
        self.headers = headers
        self.uri = uri
    }
}

public protocol MiddlewareProtocol {
    associatedtype Input
    associatedtype Output
    associatedtype Context

    func handle(
        _ request: Input,
        context: Context,
        next: (Input, Context) async throws -> Output
    ) async throws -> Output
}

public struct BasicRequestContext {}
public struct Response {}

// ── BAD: local modified copy exists but original is forwarded ─────────────────

// Direct member assignment on the copy, but original passed to next.
struct HeaderInjectMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        var modified = request
        modified.headers["X-Request-Id"] = "abc123"
        return try await next(request, context) // $ swift/middleware-request-not-forwarded
    }
}

// Subscript write through a member (modified.headers["k"] = v), original forwarded.
struct SubscriptMutationMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        var enriched = request
        enriched.headers["X-Trace"] = "trace-id"
        return try await next(request, context) // $ swift/middleware-request-not-forwarded
    }
}

// ── GOOD: modified copy is the one forwarded to next ─────────────────────────

struct HeaderInjectMiddlewareFixed: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        var modified = request
        modified.headers["X-Request-Id"] = "abc123"
        return try await next(modified, context)
    }
}

// Shadow variable: `var request = request` — the DeclRefExpr in next(...) refers to
// the local shadow, not the original parameter, so this is not flagged.
struct ShadowVariableMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        var request = request
        request.headers["X-Shadow"] = "yes"
        return try await next(request, context)
    }
}

// ── GOOD: no local request copy — read-only inspection only ──────────────────

struct LoggingMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        _ = request.uri
        return try await next(request, context)
    }
}

// ── GOOD: local Request variable, but it is not mutated ──────────────────────
// (No member assignments on `copy`, so the mutation predicate does not fire.)

struct UnmutatedCopyMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        let copy = request
        _ = copy.uri           // read-only use
        return try await next(request, context)
    }
}
