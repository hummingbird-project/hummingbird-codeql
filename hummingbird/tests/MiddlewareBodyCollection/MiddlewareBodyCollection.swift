//codeql-extractor-options:-module-name HummingbirdCore
// Test cases for the swift/middleware-body-collection query.
//
// Lines marked `// $ swift/middleware-body-collection` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Minimal stubs mirroring the Hummingbird API ───────────────────────────────

public struct Request {
    public func collectBody(upTo maxSize: Int) async throws -> [UInt8] { [] }
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
public struct SomeDTO: Decodable {}

extension Request {
    public func decode<D: Decodable>(
        as type: D.Type,
        context: BasicRequestContext
    ) async throws -> D { fatalError("stub") }
}

// ── BAD: body-draining calls inside MiddlewareProtocol.handle ─────────────────

struct BodyInspectMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        let _ = try await request.collectBody(upTo: 65536) // $ swift/middleware-body-collection
        return try await next(request, context)
    }
}

struct DecodingMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        let _ = try await request.decode(as: SomeDTO.self, context: context) // $ swift/middleware-body-collection
        return try await next(request, context)
    }
}

// ── GOOD: body collection outside middleware ───────────────────────────────────

func handleRoute(_ request: Request, context: BasicRequestContext) async throws -> Response {
    let _ = try await request.collectBody(upTo: 1_048_576)
    return Response()
}

struct AuthMiddleware: MiddlewareProtocol {
    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        return try await next(request, context)
    }
}
