/**
 * @name Blocking wait on EventLoopFuture
 * @description Calling wait() on an EventLoopFuture blocks the current thread until
 *              the future resolves. When called on an EventLoop thread this causes an
 *              immediate deadlock; even off-loop it wastes a thread and defeats the
 *              purpose of non-blocking I/O. Restructure the code to use NIOAsyncChannel
 *              so the result can be awaited in a structured async context instead.
 * @kind problem
 * @problem.severity error
 * @id swift/nio-eventloop-future-wait
 * @tags correctness
 *       concurrency
 */

import swift

/**
 * Holds if `f` is `EventLoopFuture.wait()` — a synchronous barrier that blocks the
 * calling thread and deadlocks if invoked on the EventLoop thread that owns the future.
 */
private predicate isEventLoopFutureWait(Function f) {
  f.getShortName() = "wait" and
  exists(NominalTypeDecl decl |
    decl.getName() = "EventLoopFuture" and
    decl.getAMember() = f
  )
}

from CallExpr call
where isEventLoopFutureWait(call.getStaticTarget())
select call,
  "Calling wait() on an EventLoopFuture blocks the current thread. " +
    "On an EventLoop thread this causes a deadlock; off-loop it wastes resources. " +
    "Use NIOAsyncChannel and await results in a structured async context instead."
