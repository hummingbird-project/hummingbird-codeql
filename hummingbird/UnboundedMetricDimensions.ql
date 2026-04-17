/**
 * @name Unbounded metric dimensions from HTTP request data
 * @description Using HTTP request paths directly as swift-metrics dimension values
 *              creates unbounded label cardinality. Attackers can craft unique paths
 *              to exhaust the metrics backend memory, causing denial of service.
 *              Use bounded values such as matched route patterns or a static fallback
 *              like "Unknown" instead of raw request URIs.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.5
 * @id swift/unbounded-metric-dimensions
 * @tags security
 *       correctness
 */

import swift
import codeql.swift.dataflow.DataFlow
import codeql.swift.dataflow.TaintTracking
import HummingbirdSources

module UnboundedMetricDimensionsConfig implements DataFlow::ConfigSig {
  /** Sources: any HTTP request data entering the application via Hummingbird. */
  predicate isSource(DataFlow::Node source) { source instanceof VariableInput }

  /**
   * Sinks: the `dimensions:` argument of any swift-metrics metric constructor.
   * If tainted request data flows into a dimension value it may create unbounded
   * cardinality in the metrics backend.
   */
  predicate isSink(DataFlow::Node sink) {
    exists(InitializerCallExpr call |
      call.getStaticTarget()
          .hasQualifiedName(["Counter", "Timer", "Gauge", "Histogram", "Recorder", "Meter"], _) and
      call.getArgumentWithLabel("dimensions").getExpr() = sink.asExpr()
    )
  }

  /**
   * Additional taint steps for tuple and array construction, which are not
   * modelled by the standard Swift taint library. A tainted tuple element or
   * array element taints the whole collection, which in turn can flow into the
   * `dimensions:` argument.
   */
  predicate isAdditionalFlowStep(DataFlow::Node src, DataFlow::Node sink) {
    exists(TupleExpr tuple |
      src.asExpr() = tuple.getElement(_) and
      sink.asExpr() = tuple
    )
    or
    exists(ArrayExpr arr |
      src.asExpr() = arr.getAnElement() and
      sink.asExpr() = arr
    )
  }
}

module UnboundedMetricDimensionsFlow =
  TaintTracking::Global<UnboundedMetricDimensionsConfig>;

import UnboundedMetricDimensionsFlow::PathGraph

from
  UnboundedMetricDimensionsFlow::PathNode source,
  UnboundedMetricDimensionsFlow::PathNode sink
where UnboundedMetricDimensionsFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Metric dimension value flows from $@, which is unbounded. " +
    "Use a matched route pattern or a static fallback (e.g. \"Unknown\") instead.",
  source.getNode(), "this HTTP request data"
