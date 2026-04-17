/**
 * @name Direct channel bind/connect without NIOAsyncChannel
 * @description Calling bind() or connect() on a SwiftNIO bootstrap or channel as an
 *              EventLoopFuture-based API bypasses Swift's structured concurrency model.
 *              The resulting Future has no automatic cancellation propagation, no
 *              scope-bounded lifetime, and forces callback-based lifecycle management.
 *              Use the async variants that return NIOAsyncChannel instead so that
 *              cancellation propagates automatically and the channel lifecycle stays
 *              within a structured scope.
 * @kind problem
 * @problem.severity warning
 * @id swift/nio-direct-channel-bind-connect
 * @tags correctness
 *       concurrency
 */

import swift

/**
 * Holds if `f` is a `bind` or `connect` function that returns an `EventLoopFuture` —
 * the legacy NIO API that pre-dates structured concurrency support.
 *
 * Matches both the `ServerBootstrap.bind(...)` and `ClientBootstrap.connect(...)` bootstrap
 * overloads that return `EventLoopFuture<Channel>`, as well as the `Channel.bind(to:)` and
 * `Channel.connect(to:)` extension helpers that return `EventLoopFuture<Void>`.
 * The async variants (which return `NIOAsyncChannel`) are excluded by the return-type check.
 *
 * Swift method types are curried: `(Self) -> (Args...) -> ReturnType`, so two levels of
 * `AnyFunctionType.getResult()` are needed to reach the actual return type.
 */
private predicate isDirectBindOrConnect(Function f) {
  f.getShortName() = ["bind", "connect"] and
  exists(AnyFunctionType ft |
    ft = f.getInterfaceType().(AnyFunctionType).getResult() and
    ft.getResult().(BoundGenericType).getDeclaration().getName() = "EventLoopFuture"
  )
}

from CallExpr call
where isDirectBindOrConnect(call.getStaticTarget())
select call,
  "This call returns an EventLoopFuture instead of wrapping the channel in NIOAsyncChannel. " +
    "Use the async " + call.getStaticTarget().(Function).getShortName() +
    "() variant that returns NIOAsyncChannel to integrate with Swift structured concurrency."
