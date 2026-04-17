/**
 * @name Successive NIOAsyncChannel writes that could be collated
 * @description Each call to NIOAsyncChannelOutboundWriter.write() is an async suspension
 *              point that may involve a thread hop back onto the EventLoop. Multiple
 *              successive write() calls in the same scope each pay this cost separately.
 *              Collating the parts into a single write(contentsOf:) call eliminates the
 *              extra suspensions and thread hops — see hummingbird-project/hummingbird#808
 *              for a real-world example where this change improved throughput from 122K to 165K req/s.
 * @kind problem
 * @problem.severity recommendation
 * @id swift/nio-successive-channel-writes
 * @tags performance
 */

import swift

/**
 * Holds if `f` is `NIOAsyncChannelOutboundWriter.write()` — the async per-element write
 * whose every call is a suspension point that may hop threads back onto the EventLoop.
 *
 * Swift method types are curried `(Self) -> (Args) -> Return`, so two levels of
 * `AnyFunctionType.getResult()` are needed to reach the inner function type, whose
 * `isAsync()` flag identifies the async variant.
 */
private predicate isAsyncChannelWrite(Function f) {
  f.getShortName() = "write" and
  exists(AnyFunctionType ft |
    ft = f.getInterfaceType().(AnyFunctionType).getResult() and
    ft.isAsync()
  ) and
  exists(NominalTypeDecl decl |
    decl.getName() = "NIOAsyncChannelOutboundWriter" and
    decl.getAMember() = f
  )
}

/**
 * Holds if `call1` textually precedes `call2` in the source (line/column order).
 * Used to establish a canonical ordering so each pair is reported only once.
 */
private predicate precedes(CallExpr call1, CallExpr call2) {
  call1.getLocation().getStartLine() < call2.getLocation().getStartLine()
  or
  call1.getLocation().getStartLine() = call2.getLocation().getStartLine() and
  call1.getLocation().getStartColumn() < call2.getLocation().getStartColumn()
}

from CallExpr first, CallExpr second
where
  isAsyncChannelWrite(first.getStaticTarget()) and
  isAsyncChannelWrite(second.getStaticTarget()) and
  first != second and
  // Both writes are in the same function scope.
  first.getEnclosingFunction() = second.getEnclosingFunction() and
  // Report from the earliest write in each function, paired with each later one.
  precedes(first, second) and
  not exists(CallExpr earlier |
    isAsyncChannelWrite(earlier.getStaticTarget()) and
    earlier.getEnclosingFunction() = first.getEnclosingFunction() and
    precedes(earlier, first)
  )
select first,
  "This async write and $@ in the same scope each suspend and may hop threads. " +
    "Collate both into a single write(contentsOf: [...]) call to avoid the extra suspensions.",
  second, "this subsequent write"
