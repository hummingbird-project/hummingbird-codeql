/**
 * @name Continuation resumed immediately without bridging
 * @description A continuation whose closure body contains only a resume call
 *              bridges nothing — the async wrapper adds overhead with no benefit.
 *              Return or throw directly instead.
 * @kind problem
 * @problem.severity warning
 * @id swift/immediate-continuation-resume
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

from CallExpr call, ClosureExpr closure
where
  isContinuationCall(call.getStaticTarget()) and
  closure = call.getAnArgument().getExpr() and
  count(closure.getBody().getAnElement()) = 1 and
  exists(CallExpr resume |
    resume.getEnclosingCallable() = closure and
    resume.getStaticTarget().(Method).getShortName() = "resume"
  )
select call,
  "Continuation is resumed immediately without bridging any callback. " +
    "Remove the continuation wrapper and return or throw directly."
