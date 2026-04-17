/**
 * @name Request body collected inside a Middleware
 * @description Collecting or decoding the request body inside a MiddlewareProtocol.handle
 *              method drains the underlying AsyncSequence. Any downstream handler or
 *              middleware that tries to read the body will receive an empty stream,
 *              silently discarding payload data. Re-attach the collected buffer to the
 *              request before calling `next`, or move body consumption to the route handler.
 * @kind problem
 * @problem.severity warning
 * @id swift/middleware-body-collection
 * @tags correctness
 */

import swift

/**
 * Holds if `m` is the `handle(_:context:next:)` method on a type that explicitly
 * conforms to `MiddlewareProtocol` from the Hummingbird or HummingbirdCore module.
 *
 * Uses `asNominalTypeDecl()` so that conformances declared in an extension are
 * resolved back to the struct/class/enum that owns them.
 */
private predicate isMiddlewareHandleMethod(Method m) {
  m.getShortName() = "handle" and
  exists(ProtocolDecl proto |
    proto.getName() = "MiddlewareProtocol" and
    proto.getModule().getName() in ["Hummingbird", "HummingbirdCore"] and
    m.getEnclosingDecl()
        .asNominalTypeDecl()
        .getABaseTypeDecl() = proto
  )
}

/**
 * Holds if `call` fully drains the request body stream.
 *
 * - `collectBody(upTo:)` buffers all chunks into a single `ByteBuffer`.
 * - `decode(as:context:)` calls `collectBody` internally before decoding.
 *
 * Both leave the `AsyncSequence` exhausted; no subsequent read will yield any data.
 *
 * `decode` is accepted from both `Hummingbird` (production) and `HummingbirdCore`
 * (test stubs) to allow unit tests to use a single-module stub file.
 */
private predicate isBodyDrainingCall(CallExpr call) {
  call.getStaticTarget()
      .(Method)
      .hasQualifiedName("HummingbirdCore", "Request", "collectBody(upTo:)")
  or
  call.getStaticTarget()
      .(Method)
      .hasQualifiedName("Hummingbird", "Request", "decode(as:context:)")
  or
  call.getStaticTarget()
      .(Method)
      .hasQualifiedName("HummingbirdCore", "Request", "decode(as:context:)")
}

from CallExpr call, Method handleMethod
where
  isBodyDrainingCall(call) and
  isMiddlewareHandleMethod(handleMethod) and
  call.getEnclosingFunction() = handleMethod
select call,
  "Request body is drained inside $@. " +
    "The AsyncSequence is consumed here; downstream handlers will receive an empty body. " +
    "Re-attach the collected buffer to the request before calling next, " +
    "or move body reading to the route handler.",
  handleMethod,
  handleMethod.getEnclosingDecl().asNominalTypeDecl().getName() + ".handle(_:context:next:)"
