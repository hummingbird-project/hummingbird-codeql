/**
 * @name AsyncStream created without explicit buffering policy
 * @description AsyncStream's bufferingPolicy defaults to .unbounded when the argument
 *              is omitted. Under a fast producer this allows the internal buffer to grow
 *              without limit until the process runs out of memory. Either pass an explicit
 *              bufferingPolicy (using .bufferingNewest or .bufferingOldest to cap the
 *              buffer), or replace AsyncStream with AsyncChannel from swift-async-algorithms,
 *              which provides structured producer/consumer flow control without any buffer.
 *              Note: explicitly passing bufferingPolicy: .unbounded is not flagged — that
 *              is a deliberate choice and there are legitimate uses for unbounded buffering.
 * @kind problem
 * @problem.severity warning
 * @id swift/async-stream-unbounded-buffer
 * @tags correctness
 *       concurrency
 */

import swift

/**
 * Holds if `f` is an `AsyncStream` constructor or factory that accepts a
 * `bufferingPolicy` argument — i.e. one of:
 *   - `AsyncStream.init(_:bufferingPolicy:_:)`
 *   - `AsyncStream.makeStream(of:bufferingPolicy:)`  (Swift 5.9+)
 *
 * Both default bufferingPolicy to .unbounded when the argument is omitted.
 */
private predicate isAsyncStreamBufferedEntry(Function f) {
  exists(NominalTypeDecl asyncStream |
    asyncStream.getName() in ["AsyncStream", "AsyncThrowingStream"] and
    asyncStream.getAMember() = f and
    (f instanceof Initializer or f.getShortName() = "makeStream")
  )
}

from CallExpr call
where
  isAsyncStreamBufferedEntry(call.getStaticTarget()) and
  // bufferingPolicy omitted — default is .unbounded, which allows the buffer
  // to grow without limit and can exhaust memory under a fast producer.
  not exists(call.getArgumentWithLabel("bufferingPolicy")) and
  // Exclude the AsyncStream(unfolding:) pull-model overload; it has no
  // buffering policy because elements are produced on demand.
  not exists(call.getArgumentWithLabel("unfolding"))
select call,
  "AsyncStream initialised without an explicit bufferingPolicy — the default is " +
    ".unbounded, which lets the buffer grow without limit and can exhaust memory under " +
    "a fast producer. Either pass bufferingPolicy: .bufferingNewest(N) or " +
    ".bufferingOldest(N) to cap the buffer, or consider replacing AsyncStream with " +
    "AsyncChannel from swift-async-algorithms, which uses structured flow control " +
    "instead of a buffer."
