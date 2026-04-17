/**
 * @name Request modifications lost — original request forwarded to next in middleware
 * @description A local variable of the same type as the request was declared inside
 *              MiddlewareProtocol.handle and has member assignments applied to it
 *              (indicating a modified copy), but the original request parameter was
 *              passed to next instead. All edits to the local copy will be silently
 *              discarded by downstream handlers.
 * @kind problem
 * @problem.severity warning
 * @id swift/middleware-request-not-forwarded
 * @tags correctness
 */

import swift

/**
 * Holds if `m` is the `handle(_:context:next:)` method on a type that explicitly
 * conforms to `MiddlewareProtocol` from the Hummingbird or HummingbirdCore module.
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
 * Holds if `call` is an invocation of the `next` closure parameter within `handleMethod`.
 *
 * In `handle(_ request: Input, context: Context, next: ...)`, `next` is the third
 * parameter (index 2). We identify its call sites by checking that the callee
 * expression is a direct reference to that parameter.
 */
private predicate isNextCall(CallExpr call, Method handleMethod) {
  isMiddlewareHandleMethod(handleMethod) and
  call.getEnclosingFunction() = handleMethod and
  call.getFunction().(DeclRefExpr).getDecl() = handleMethod.getParam(2)
}

/**
 * Holds if `local` is a non-parameter variable declared inside `handleMethod`
 * whose type matches the request parameter type — suggesting it is a (modified)
 * copy of the incoming request.
 */
private predicate isLocalRequestVar(VarDecl local, Method handleMethod) {
  isMiddlewareHandleMethod(handleMethod) and
  local.getEnclosingFunction() = handleMethod and
  not local instanceof ParamDecl and
  local.getType() = handleMethod.getParam(0).getType()
}

/**
 * Holds if `local` has at least one member-level write inside `handleMethod`.
 *
 * Catches the common pattern:
 *   var modified = request
 *   modified.headers["X-Custom"] = "value"   // <-- AssignExpr on member of modified
 *
 * Direct member assignment (`modified.field = value`) is matched at one level of
 * indirection; subscript writes such as `modified.field[key] = value` are matched
 * at two levels.
 */
private predicate isMutated(VarDecl local, Method handleMethod) {
  exists(AssignExpr ae |
    ae.getEnclosingFunction() = handleMethod and
    (
      // modified.field = value
      ae.getDest().(MemberRefExpr).getBase().(DeclRefExpr).getDecl() = local
      or
      // modified.field[key] = value
      ae.getDest().(SubscriptExpr).getBase().(MemberRefExpr).getBase().(DeclRefExpr).getDecl() =
        local
    )
  )
}

from CallExpr nextCall, Method handleMethod
where
  isNextCall(nextCall, handleMethod) and
  // next is called with the original (unmodified) request parameter
  nextCall.getArgument(0).getExpr().(DeclRefExpr).getDecl() = handleMethod.getParam(0) and
  // a local variable of the request type was mutated in the same function
  exists(VarDecl local |
    isLocalRequestVar(local, handleMethod) and
    isMutated(local, handleMethod)
  )
select nextCall,
  "Original (unmodified) request forwarded to $@ — a modified local copy exists but was not " +
    "passed to next. Edits to the local copy will be silently discarded by downstream handlers. " +
    "Pass the modified request to next instead.",
  handleMethod,
  handleMethod.getEnclosingDecl().asNominalTypeDecl().getName() + ".handle(_:context:next:)"
