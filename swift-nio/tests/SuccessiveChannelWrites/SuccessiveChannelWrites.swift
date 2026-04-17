//codeql-extractor-options:-module-name NIOCore
// Test cases for the swift/nio-successive-channel-writes query.
//
// Lines marked `// $ swift/nio-successive-channel-writes` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Stubs ──────────────────────────────────────────────────────────────────────

public struct NIOAsyncChannelOutboundWriter<OutboundOut> {
    public func write(_ data: OutboundOut) async throws {}
    public func write<Writes: Sequence>(contentsOf sequence: Writes) async throws
    where Writes.Element == OutboundOut {}
}

// ── BAD: multiple async writes — each suspends and may hop threads ─────────────

// Classic head + body + end pattern.
func badHeadBodyEnd(writer: NIOAsyncChannelOutboundWriter<String>) async throws {
    try await writer.write("head")   // $ swift/nio-successive-channel-writes
    try await writer.write("body")
    try await writer.write("end")
}

// Two-part write.
func badTwoParts(writer: NIOAsyncChannelOutboundWriter<String>) async throws {
    try await writer.write("part1")  // $ swift/nio-successive-channel-writes
    try await writer.write("part2")
}

// ── GOOD: single write or batched via write(contentsOf:) ──────────────────────

func goodSingleWrite(writer: NIOAsyncChannelOutboundWriter<String>) async throws {
    try await writer.write("only")
}

func goodCollated(writer: NIOAsyncChannelOutboundWriter<String>) async throws {
    try await writer.write(contentsOf: ["head", "body", "end"])
}
