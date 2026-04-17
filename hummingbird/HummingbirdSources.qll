/**
 * Provides source definitions for the Hummingbird Swift HTTP framework.
 *
 * Extends `RemoteFlowSource` to mark all HTTP request data entry points as
 * untrusted. Import this library from taint-tracking queries that analyse
 * Hummingbird applications.
 *
 * See: https://github.com/hummingbird-project/hummingbird
 */

import swift
import codeql.swift.dataflow.DataFlow
import codeql.swift.dataflow.FlowSources

/**
 * A Hummingbird HTTP request data source — user-controlled input that enters
 * the application via an inbound HTTP request.
 *
 * Extend this class or use `RemoteFlowSource` directly in taint-tracking
 * configurations. Every concrete subclass below covers one distinct entry point.
 */
abstract class VariableInput extends RemoteFlowSource { }

// ---------------------------------------------------------------------------
// Request body
// ---------------------------------------------------------------------------

/**
 * The `body` property of `HummingbirdCore.Request`.
 *
 * Returns a `RequestBody` (an `AsyncSequence` of `ByteBuffer` chunks).
 * Any downstream iteration, collection, or decoding of this value is tainted.
 *
 * ```swift
 * let body = request.body   // <-- source
 * ```
 */
private class RequestBodyPropertySource extends VariableInput {
  RequestBodyPropertySource() {
    exists(MemberRefExpr mre |
      mre.getMember().(FieldDecl).hasQualifiedName("HummingbirdCore", "Request", "body") and
      this.asExpr() = mre
    )
  }

  override string getSourceType() { result = "Hummingbird request body" }
}

/**
 * Calls to `Request.collectBody(upTo:)`, which collapses all body chunks into
 * a single `ByteBuffer` and stores the result back on the request.
 *
 * ```swift
 * let buffer = try await request.collectBody(upTo: maxSize)   // <-- source
 * ```
 */
private class CollectBodyCallSource extends VariableInput {
  CollectBodyCallSource() {
    exists(CallExpr ce |
      ce.getStaticTarget()
          .(Method)
          .hasQualifiedName("HummingbirdCore", "Request", "collectBody(upTo:)") and
      this.asExpr() = ce
    )
  }

  override string getSourceType() { result = "Hummingbird collected request body" }
}

/**
 * Calls to `Request.decode(as:context:)`, which decodes the request body into
 * a `Decodable` value using the context's configured decoder (JSON by default).
 *
 * ```swift
 * let dto = try await request.decode(as: MyDTO.self, context: context)   // <-- source
 * ```
 */
private class RequestDecodeCallSource extends VariableInput {
  RequestDecodeCallSource() {
    exists(CallExpr ce |
      ce.getStaticTarget()
          .(Method)
          .hasQualifiedName("Hummingbird", "Request", "decode(as:context:)") and
      this.asExpr() = ce
    )
  }

  override string getSourceType() { result = "Hummingbird decoded request body" }
}

// ---------------------------------------------------------------------------
// URI and query parameters
// ---------------------------------------------------------------------------

/**
 * The `uri` property of `HummingbirdCore.Request` — the full request URI.
 *
 * Any property of the resulting `URI` value (`path`, `query`, `queryParameters`,
 * etc.) is also user-controlled and will be tainted transitively.
 *
 * ```swift
 * let uri = request.uri   // <-- source
 * ```
 */
private class RequestUriPropertySource extends VariableInput {
  RequestUriPropertySource() {
    exists(MemberRefExpr mre |
      mre.getMember().(FieldDecl).hasQualifiedName("HummingbirdCore", "Request", "uri") and
      this.asExpr() = mre
    )
  }

  override string getSourceType() { result = "Hummingbird request URI" }
}

/**
 * The `query` property of `HummingbirdCore.URI` — the raw, unparsed query string.
 *
 * ```swift
 * let qs = request.uri.query   // <-- source
 * ```
 */
private class UriQueryPropertySource extends VariableInput {
  UriQueryPropertySource() {
    exists(MemberRefExpr mre |
      mre.getMember().(FieldDecl).hasQualifiedName("HummingbirdCore", "URI", "query") and
      this.asExpr() = mre
    )
  }

  override string getSourceType() { result = "Hummingbird URI query string" }
}

/**
 * The `queryParameters` property of `HummingbirdCore.URI` — the query string
 * parsed into a `FlatDictionary<Substring, Substring>` (typealias `Parameters`).
 *
 * ```swift
 * let params = request.uri.queryParameters   // <-- source
 * ```
 */
private class UriQueryParametersPropertySource extends VariableInput {
  UriQueryParametersPropertySource() {
    exists(MemberRefExpr mre |
      mre.getMember()
          .(FieldDecl)
          .hasQualifiedName("HummingbirdCore", "URI", "queryParameters") and
      this.asExpr() = mre
    )
  }

  override string getSourceType() { result = "Hummingbird URI query parameters" }
}

/**
 * Calls to `URI.decodeQuery(as:context:)`, which URL-decodes the query string
 * into a `Decodable` value using `URLEncodedFormDecoder`.
 *
 * ```swift
 * let filter = try request.uri.decodeQuery(as: FilterDTO.self, context: context)   // <-- source
 * ```
 */
private class UriDecodeQueryCallSource extends VariableInput {
  UriDecodeQueryCallSource() {
    exists(CallExpr ce |
      ce.getStaticTarget()
          .(Method)
          .hasQualifiedName("Hummingbird", "URI", "decodeQuery(as:context:)") and
      this.asExpr() = ce
    )
  }

  override string getSourceType() { result = "Hummingbird decoded URI query" }
}

// ---------------------------------------------------------------------------
// Path / route parameters
// ---------------------------------------------------------------------------

/**
 * The `parameters` property on any `RequestContext`-conforming type, which
 * contains the path components captured by the router (e.g. `":id"`).
 *
 * The underlying type is `FlatDictionary<Substring, Substring>` (typealias
 * `Parameters`). Individual values are extracted with `.get`, `.require`, etc.
 *
 * ```swift
 * let params = context.parameters   // <-- source
 * ```
 */
private class ContextParametersPropertySource extends VariableInput {
  ContextParametersPropertySource() {
    exists(MemberRefExpr mre |
      // `parameters` is declared both on CoreRequestContextStorage (stored) and
      // via a RequestContext extension (computed). Both live in Hummingbird.
      mre.getMember().(FieldDecl).hasQualifiedName("Hummingbird", "CoreRequestContextStorage", "parameters") and
      this.asExpr() = mre
    )
  }

  override string getSourceType() { result = "Hummingbird path parameters" }
}

/**
 * Calls to path-parameter extraction methods defined in `Hummingbird` as
 * extensions on `FlatDictionary<Substring, Substring>` (i.e. `Parameters`):
 *
 * - `get(_:)` / `get(_:as:)`
 * - `require(_:)` / `require(_:as:)`
 * - `getAll(_:)` / `getAll(_:as:)`
 * - `requireAll(_:as:)`
 * - `getCatchAll()`
 *
 * ```swift
 * let id   = context.parameters.get("id")          // <-- source
 * let name = try context.parameters.require("name") // <-- source
 * ```
 */
private class ParameterValueSource extends VariableInput {
  ParameterValueSource() {
    exists(CallExpr ce, Method m |
      ce.getStaticTarget() = m and
      m.getModule().getFullName() = "Hummingbird" and
      m.getShortName() in ["get", "require", "getAll", "requireAll", "getCatchAll"] and
      this.asExpr() = ce
    )
  }

  override string getSourceType() { result = "Hummingbird path parameter value" }
}

// ---------------------------------------------------------------------------
// HTTP headers
// ---------------------------------------------------------------------------

/**
 * The `headers` property of `HummingbirdCore.Request` — an `HTTPFields` value
 * containing all inbound HTTP header fields.
 *
 * Individual headers are accessed via subscript: `request.headers[.authorization]`.
 * Taint propagates to any subscript or iteration result automatically.
 *
 * ```swift
 * let hdrs = request.headers   // <-- source
 * ```
 */
private class RequestHeadersPropertySource extends VariableInput {
  RequestHeadersPropertySource() {
    exists(MemberRefExpr mre |
      mre.getMember().(FieldDecl).hasQualifiedName("HummingbirdCore", "Request", "headers") and
      this.asExpr() = mre
    )
  }

  override string getSourceType() { result = "Hummingbird request headers" }
}

// ---------------------------------------------------------------------------
// Cookies
// ---------------------------------------------------------------------------

/**
 * The `cookies` property of `Request` (added by the `Hummingbird` module's
 * `Request+Cookies.swift` extension) — a `Cookies` value parsed from the
 * `Cookie` request header.
 *
 * Individual cookies are accessed via subscript: `request.cookies["session"]`.
 *
 * ```swift
 * let jar = request.cookies   // <-- source
 * ```
 */
private class RequestCookiesPropertySource extends VariableInput {
  RequestCookiesPropertySource() {
    exists(MemberRefExpr mre |
      mre.getMember().(FieldDecl).hasQualifiedName("Hummingbird", "Request", "cookies") and
      this.asExpr() = mre
    )
  }

  override string getSourceType() { result = "Hummingbird request cookies" }
}
