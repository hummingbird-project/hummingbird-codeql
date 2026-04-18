# Hummingbird CodeQL

CodeQL query suite for static analysis of Swift server-side codebases built with [Hummingbird](https://github.com/hummingbird-project/hummingbird), [Swift-NIO](https://github.com/apple/swift-nio), and structured concurrency patterns.

## Query Packs

### `hummingbird/` — Hummingbird web framework

Improve the quality of your Hummingbird apps by catching common mistakes.

| Query | Severity | Description |
|-------|----------|-------------|
| `UnboundedMetricDimensions` | Error | HTTP request data (paths, URIs) flowing into metrics dimensions — creates unbounded label cardinality and enables DoS |
| `UnboundedBodyCollection` | Error | `collectBody(upTo:)` called with `Int.max` or values ≥ 100 MB — allows clients to exhaust server memory |
| `MiddlewareBodyCollection` | Warning | Request body consumed inside `MiddlewareProtocol.handle` — drains the `AsyncSequence`, leaving downstream handlers with an empty body |
| `MiddlewareRequestNotForwarded` | Warning | Modified request copies not passed to `next` — edits are silently discarded |

### `strict-concurrency/` — Swift structured concurrency

Checks for common concurrency issues, and warns on anti-patterns for structured concurrency applications.

| Query | Severity | Description |
|-------|----------|-------------|
| `DroppedContinuation` | Error | Continuation never resumed on any code path — task hangs indefinitely |
| `MultipleContinuationResumes` | Error | Continuation resumed more than once — undefined behaviour or runtime trap |
| `UnsafeContinuation` | Warning | `withUnsafeContinuation` used instead of the checked variant |
| `UnstructuredTask` | Warning | `Task.init` / `Task.detached` used — escapes structured concurrency; cancellation doesn't propagate |
| `ImmediateContinuationResume` | Warning | Continuation closure only resumes immediately — unnecessary async wrapper overhead |

### `swift-nio/` — SwiftNIO networking

Marks anti-patterns, and detects possible optimizations in SwiftNIO-based networking code

| Query | Severity | Description |
|-------|----------|-------------|
| `EventLoopFutureWait` | Error | `EventLoopFuture.wait()` called — blocks the thread and deadlocks on EventLoop threads |
| `DirectChannelWrite` | Warning | `channel.write()` returning `EventLoopFuture` — bypasses backpressure and structured concurrency |
| `DirectChannelBindConnect` | Warning | `bind()` / `connect()` returning `EventLoopFuture` — legacy API incompatible with async/await |
| `SuccessiveChannelWrites` | Recommendation | Multiple successive `write()` calls — collate into `write(contentsOf:)` for better throughput |

## Requirements

- [CodeQL CLI](https://github.com/github/codeql-cli-binaries/releases) (tested with v2.25.2)
- Swift extractor for CodeQL (bundled with the CLI)

## Usage

**1. Build a database from your Swift source:**

```bash
codeql database create mydb --language=swift --source-root=/path/to/your/swift/repo
```

**2. Run a query pack against it:**

```bash
codeql query run hummingbird/*.ql --database=mydb
codeql query run strict-concurrency/*.ql --database=mydb
codeql query run swift-nio/*.ql --database=mydb
```

**3. Decode results:**

```bash
codeql bqrs decode <results.bqrs> --output=results.csv --format=csv
```

**4. Run the test suite:**

```bash
codeql test run hummingbird/tests/
codeql test run strict-concurrency/tests/
codeql test run swift-nio/tests/
```

## Repository Layout

```
hb-codeql/
├── hummingbird/
│   ├── HummingbirdSources.qll   # Taint sources for HTTP request data
│   ├── *.ql                     # Queries
│   └── tests/                   # Test cases with expected results
├── strict-concurrency/
│   ├── *.ql
│   └── tests/
├── swift-nio/
│   ├── *.ql
│   └── tests/
└── databases/                   # Pre-built CodeQL databases (not committed)
```

Each pack's `codeql-pack.yml` declares a dependency on `codeql/swift-all ^6.3.3`.
