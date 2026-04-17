// Test cases for the swift/unbounded-metric-dimensions query.
//
// Lines marked `// $ swift/unbounded-metric-dimensions` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Minimal stubs that mirror the swift-metrics API ──────────────────────────

struct Counter {
    init(label: String, dimensions: [(String, String)] = []) {}
    func increment(by: Int = 1) {}
}

struct Timer {
    init(label: String, dimensions: [(String, String)] = []) {}
    func recordNanoseconds(_ duration: Int) {}
}

struct Gauge {
    init(label: String, dimensions: [(String, String)] = []) {}
    func record(_ value: Int) {}
}

struct Histogram {
    init(label: String, dimensions: [(String, String)] = []) {}
    func record(_ value: Double) {}
}

struct URI {
    var path: String
}

struct Request {
    var uri: URI
}

// ── BAD: unbounded path flows into metric dimension ───────────────────────────

func badDirectPath(request: Request) {
    // The raw request path is used as a dimension value; every unique path
    // creates a new metric series, which is unbounded.
    let counter = Counter(
        label: "http_requests_total",
        dimensions: [("path", request.uri.path)] // $ swift/unbounded-metric-dimensions
    )
    counter.increment()
}

func badViaLocalVar(request: Request) {
    // Taint still flows through a local variable.
    let rawPath = request.uri.path
    let timer = Timer(
        label: "http_request_duration",
        dimensions: [("route", rawPath)] // $ swift/unbounded-metric-dimensions
    )
    timer.recordNanoseconds(1_000)
}

func badStringInterpolation(request: Request) {
    // Interpolation does not bound the cardinality.
    let label = "endpoint:\(request.uri.path)"
    let gauge = Gauge(
        label: "active_requests",
        dimensions: [("endpoint", label)] // $ swift/unbounded-metric-dimensions
    )
    gauge.record(1)
}

// ── GOOD: bounded values used as dimensions ───────────────────────────────────

func goodKnownRoute(routerPattern: String?) {
    // The dimension is the matched router pattern (a finite set of strings)
    // or a static fallback — never the raw request path.
    let endpoint = routerPattern ?? "Unknown"
    let counter = Counter(
        label: "http_requests_total",
        dimensions: [("endpoint", endpoint)]
    )
    counter.increment()
}

func goodStaticDimensions() {
    // Entirely static dimensions are always safe.
    let counter = Counter(
        label: "cache_hits_total",
        dimensions: [("region", "eu-west-1"), ("tier", "hot")]
    )
    counter.increment()
}

func goodNotFoundFallback(endpointPath: String?) {
    // Matches the pattern from hummingbird/pull/793:
    // unmatched paths are normalised to the static string "NotFound".
    let path = endpointPath ?? "NotFound"
    let counter = Counter(
        label: "http_requests_total",
        dimensions: [("endpoint", path)]
    )
    counter.increment()
}
