/**
 * @name Direct channel write without NIOAsyncChannel
 * @description Calling channel.write() or channel.writeAndFlush() as EventLoopFuture
 *              variants bypasses Swift's structured concurrency model. There is no
 *              automatic backpressure, cancellation does not propagate, and the caller
 *              must manually chain futures to know when the write completes. Use
 *              NIOAsyncChannel's AsyncWriter to send data instead so that backpressure,
 *              cancellation and channel lifecycle are managed automatically.
 * @kind problem
 * @problem.severity warning
 * @id swift/nio-direct-channel-write
 * @tags correctness
 *       concurrency
 */

import swift

/**
 * Holds if `f` is a `write` or `writeAndFlush` method that returns an `EventLoopFuture` —
 * the legacy NIO API superseded by `NIOAsyncChannel.AsyncWriter`.
 *
 * Swift method types are curried `(Self) -> (Args) -> Return`, so two levels of
 * `AnyFunctionType.getResult()` are needed to reach the actual return type.
 */
private predicate isDirectWrite(Function f) {
  f.getShortName() = ["write", "writeAndFlush"] and
  exists(AnyFunctionType ft |
    ft = f.getInterfaceType().(AnyFunctionType).getResult() and
    ft.getResult().(BoundGenericType).getDeclaration().getName() = "EventLoopFuture"
  )
}

from CallExpr call
where isDirectWrite(call.getStaticTarget())
select call,
  "This call returns an EventLoopFuture instead of using NIOAsyncChannel's AsyncWriter. " +
    "Use NIOAsyncChannel to send data so that backpressure, cancellation and " +
    "channel lifecycle are managed automatically."
