/**
 * @name Continuation never resumed
 * @description A continuation that is never resumed leaves the suspended task
 *              waiting indefinitely, leaking its stack and any held resources.
 *              Every code path through the closure must resume the continuation.
 * @kind problem
 * @problem.severity error
 * @id swift/dropped-continuation
 * @tags correctness
 *       concurrency
 */

import swift

private predicate isContinuationCall(Function fd) {
  fd.getModule().getName() = "_Concurrency" and
  fd.getShortName() =
    [
      "withCheckedContinuation", "withCheckedThrowingContinuation",
      "withUnsafeContinuation", "withUnsafeThrowingContinuation"
    ]
}

/** Holds if a resume call exists directly inside `closure` or one level deeper. */
private predicate hasResumeInClosure(ClosureExpr closure) {
  exists(CallExpr resume |
    resume.getStaticTarget().(Method).getShortName() = "resume" and
    (
      resume.getEnclosingCallable() = closure
      or
      exists(ClosureExpr inner |
        resume.getEnclosingCallable() = inner and
        inner.getEnclosingCallable() = closure
      )
    )
  )
}

/**
 * Holds if the continuation parameter escapes the closure — passed as an argument
 * to another call or stored via assignment — meaning it will be resumed later.
 */
private predicate continuationEscapes(ClosureExpr closure) {
  exists(DeclRefExpr use | use = closure.getParam(0).getAnAccess() |
    exists(CallExpr c | c.getAnArgument().getExpr() = use)
    or
    exists(AssignExpr assign | assign.getSource() = use)
  )
}

from CallExpr call, ClosureExpr closure
where
  isContinuationCall(call.getStaticTarget()) and
  closure = call.getAnArgument().getExpr() and
  not hasResumeInClosure(closure) and
  not continuationEscapes(closure)
select call,
  "Continuation is never resumed. The suspended task will hang indefinitely, " +
    "leaking its stack and any held resources."
