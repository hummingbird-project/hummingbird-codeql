/**
 * @name Use of unstructured Task
 * @description Creating a Task directly escapes Swift's structured concurrency
 *              hierarchy: the new task is not a child of the current task group,
 *              so cancellation does not propagate automatically and the parent
 *              cannot await its completion. Prefer async let, withTaskGroup, or
 *              withThrowingTaskGroup to keep tasks within a structured scope.
 * @kind problem
 * @problem.severity warning
 * @id swift/unstructured-task
 * @tags correctness
 *       concurrency
 */

import swift

/**
 * Holds if `fd` creates an unstructured task — either a `Task.init` constructor
 * or the `Task.detached` static factory, both from the `_Concurrency` module.
 *
 * `Task.init` inherits priority and task-local values from the calling context
 * but is still unstructured (the child outlives the parent scope).
 * `Task.detached` is even more unstructured: it inherits neither.
 */
private predicate isUnstructuredTaskDecl(Function fd) {
  exists(NominalTypeDecl taskDecl |
    taskDecl.getName() = "Task" and
    taskDecl.getModule().getName() = "_Concurrency" and
    (
      fd.(Initializer).getEnclosingDecl() = taskDecl
      or
      fd.getEnclosingDecl() = taskDecl and fd.getShortName() = "detached"
    )
  )
}

from CallExpr call
where isUnstructuredTaskDecl(call.getStaticTarget())
select call,
  "Unstructured Task escapes structured concurrency: cancellation does not propagate " +
    "and the parent cannot await completion. " +
    "Prefer async let, withTaskGroup, or withThrowingTaskGroup instead."
