/**
 * @name Continuation resumed multiple times
 * @description Resuming a continuation more than once is undefined behaviour with
 *              UnsafeContinuation and a runtime trap with CheckedContinuation.
 *              Each continuation must be resumed exactly once.
 * @kind problem
 * @problem.severity error
 * @id swift/multiple-continuation-resumes
 * @tags correctness
 *       concurrency
 */

import swift
import codeql.swift.generated.ParentChild

private predicate isContinuationCall(Function fd) {
  fd.getModule().getName() = "_Concurrency" and
  fd.getShortName() =
    [
      "withCheckedContinuation", "withCheckedThrowingContinuation",
      "withUnsafeContinuation", "withUnsafeThrowingContinuation"
    ]
}

/**
 * Holds if the continuation parameter escapes the closure — passed as an argument
 * to another call or stored via assignment — meaning resume is managed externally.
 * Multiple resume calls in such closures are state machine dispatch patterns, not bugs.
 */
private predicate continuationEscapes(ClosureExpr closure) {
  exists(DeclRefExpr use | use = closure.getParam(0).getAnAccess() |
    exists(CallExpr c | c.getAnArgument().getExpr() = use)
    or
    exists(AssignExpr assign | assign.getSource() = use)
  )
}

/** Gets a direct child of `e` (resolved). Used for transitive descendant checks. */
private Element getAChildOf(Element e) { result = getChild(e, _) }

/**
 * Holds if `call` is nested inside a conditional branch within `closure`:
 * a then/else block of an if, a switch case body, or a guard body.
 * Such resumes are on mutually exclusive paths and should not be flagged.
 */
private predicate isInsideConditional(CallExpr call, ClosureExpr closure) {
  call.getEnclosingCallable() = closure and
  exists(Stmt cond |
    (cond instanceof SwitchStmt or cond instanceof IfStmt or cond instanceof GuardStmt) and
    cond.getEnclosingCallable() = closure and
    getAChildOf+(cond) = call
  )
}

from CallExpr call, ClosureExpr closure
where
  isContinuationCall(call.getStaticTarget()) and
  closure = call.getAnArgument().getExpr() and
  not continuationEscapes(closure) and
  exists(CallExpr r1, CallExpr r2 |
    r1 != r2 and
    r1.getEnclosingCallable() = closure and
    r2.getEnclosingCallable() = closure and
    r1.getStaticTarget().(Method).getShortName() = "resume" and
    r2.getStaticTarget().(Method).getShortName() = "resume" and
    not isInsideConditional(r1, closure) and
    not isInsideConditional(r2, closure)
  )
select call,
  "Continuation has multiple resume calls in the same scope. " +
    "Each continuation must be resumed exactly once."
