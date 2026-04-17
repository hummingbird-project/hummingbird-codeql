/**
 * @name Use of unsafe continuation
 * @description Using withUnsafeContinuation or withUnsafeThrowingContinuation bypasses
 *              Swift's runtime checks for continuation misuse (resuming twice or never).
 *              Prefer withCheckedContinuation or withCheckedThrowingContinuation, which
 *              trap on these mistakes during development and testing.
 * @kind problem
 * @problem.severity warning
 * @id swift/unsafe-continuation
 * @tags correctness
 *       concurrency
 */

import swift

private predicate isUnsafeContinuationCall(Function fd) {
  fd.getModule().getName() = "_Concurrency" and
  fd.getShortName() = ["withUnsafeContinuation", "withUnsafeThrowingContinuation"]
}

from CallExpr call
where isUnsafeContinuationCall(call.getStaticTarget())
select call,
  "Unsafe continuation bypasses runtime checks for double-resume and missing resume. " +
    "Use withCheckedContinuation or withCheckedThrowingContinuation instead."
