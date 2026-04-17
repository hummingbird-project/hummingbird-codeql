/**
 * @name Explore Task.detached (debug)
 * @kind problem
 * @id swift/explore-task-debug
 * @problem.severity warning
 */

import swift

from Method m
where
  m.getModule().getFullName() = "_Concurrency" and
  m.getShortName() = "detached"
select m, m.getName()
