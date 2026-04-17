//codeql-extractor-options:-module-name NIOCore
// Test cases for the swift/nio-direct-channel-write query.
//
// Lines marked `// $ swift/nio-direct-channel-write` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Stubs mirroring SwiftNIO's Channel write API ──────────────────────────────

public struct EventLoopFuture<T> {}

public struct NIOAny {}

public struct EventLoopPromise<T> {}

// Channel with both EventLoopFuture-returning variants (flagged) and
// promise-based variants (clean, no return value).
public class SocketChannel {
    public func write(_ data: NIOAny) -> EventLoopFuture<Void> { fatalError() }
    public func write(_ data: NIOAny, promise: EventLoopPromise<Void>?) { fatalError() }
    public func writeAndFlush(_ data: NIOAny) -> EventLoopFuture<Void> { fatalError() }
    public func writeAndFlush(_ data: NIOAny, promise: EventLoopPromise<Void>?) { fatalError() }
}

// NIOAsyncChannel writer — the correct modern API (clean).
public struct NIOAsyncChannelOutboundWriter<OutboundOut> {
    public func write(_ data: OutboundOut) async throws { fatalError() }
    public func finish() { fatalError() }
}

// ── BAD: EventLoopFuture-based write ─────────────────────────────────────────

func badWrite(ch: SocketChannel) {
    _ = ch.write(NIOAny()) // $ swift/nio-direct-channel-write
}

func badWriteAndFlush(ch: SocketChannel) {
    _ = ch.writeAndFlush(NIOAny()) // $ swift/nio-direct-channel-write
}

// ── GOOD: promise-based write (void, not ELF) ────────────────────────────────

func goodWriteWithPromise(ch: SocketChannel) {
    ch.write(NIOAny(), promise: nil)
}

func goodWriteAndFlushWithPromise(ch: SocketChannel) {
    ch.writeAndFlush(NIOAny(), promise: nil)
}

// ── GOOD: NIOAsyncChannel writer ─────────────────────────────────────────────

func goodAsyncChannelWrite(writer: NIOAsyncChannelOutboundWriter<String>) async throws {
    try await writer.write("hello")
}
