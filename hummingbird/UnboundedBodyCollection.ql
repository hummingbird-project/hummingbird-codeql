/**
 * @name Unbounded or excessively large request body collection
 * @description Calling collectBody(upTo:) with Int.max or a byte cap above 100 MB
 *              allows a client to send an arbitrarily large body and exhaust server
 *              memory, causing denial of service. Use a strict, route-appropriate
 *              constant that reflects the real maximum payload size.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @id swift/unbounded-body-collection
 * @tags security
 */

import swift

/**
 * A generous but still bounded body-size limit: 100 MiB (104 857 600 bytes).
 * Any literal at or above this value is flagged as "ridiculously high".
 * Adjust this threshold to match your organisation's policy.
 */
private int bodyBytesThreshold() { result = 104857600 }

/**
 * Holds if `expr` resolves to `Int.max` (or any `FixedWidthInteger.max` that,
 * through type inference, ends up as the `upTo:` argument of `collectBody`).
 *
 * Covers both the explicit form `Int.max` and the shorthand `.max`.
 */
private predicate isIntMax(Expr expr) {
  exists(MemberRefExpr mre |
    mre.getMember().(VarDecl).getName() = "max" and
    mre.getMember().(VarDecl).getModule().getName() = "Swift" and
    expr = mre
  )
}

/**
 * Holds if `expr` is an integer literal whose numeric value equals or exceeds
 * `bodyBytesThreshold()`.
 *
 * Only plain (non-negative) literals are checked; variables and expressions
 * require taint tracking and are out of scope here.
 */
private predicate isExcessiveLiteral(Expr expr) {
  exists(IntegerLiteralExpr lit |
    expr = lit and
    lit.getStringValue().toInt() >= bodyBytesThreshold()
  )
}

from CallExpr call, Expr limitArg
where
  call.getStaticTarget()
      .(Method)
      .hasQualifiedName("HummingbirdCore", "Request", "collectBody(upTo:)") and
  limitArg = call.getArgumentWithLabel("upTo").getExpr() and
  (isIntMax(limitArg) or isExcessiveLiteral(limitArg))
select call,
  "collectBody(upTo:) uses $@ as its byte cap. " +
    "A client that sends a very large body can exhaust server memory. " +
    "Replace this with a strict, route-appropriate constant (e.g. 1 MB = 1_048_576).",
  limitArg, "this limit"
