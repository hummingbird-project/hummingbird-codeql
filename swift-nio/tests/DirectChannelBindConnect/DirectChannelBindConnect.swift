//codeql-extractor-options:-module-name NIOPosix
// Test cases for the swift/nio-direct-channel-bind-connect query.
//
// Lines marked `// $ swift/nio-direct-channel-bind-connect` are expected to be flagged.
// Lines without the annotation are expected to be clean.

// ── Stubs mirroring SwiftNIO's bootstrap and channel API ─────────────────────

public class Channel {}

public struct EventLoopFuture<T> {
    public init() {}
}

public struct SocketAddress {}

public struct NIOAsyncChannel<Inbound, Outbound> {}

// ServerBootstrap: ELF-returning overloads (flagged) and async overload (clean).
public class ServerBootstrap {
    public func bind(host: String, port: Int) -> EventLoopFuture<Channel> { fatalError() }
    public func bind(to address: SocketAddress) -> EventLoopFuture<Channel> { fatalError() }
    public func bind(
        host: String,
        port: Int,
        childChannelInitializer: @escaping (Channel) -> EventLoopFuture<Void>
    ) async throws -> NIOAsyncChannel<Void, Never> { fatalError() }
}

// ClientBootstrap: ELF-returning overloads (flagged) and async overload (clean).
public class ClientBootstrap {
    public func connect(host: String, port: Int) -> EventLoopFuture<Channel> { fatalError() }
    public func connect(to address: SocketAddress) -> EventLoopFuture<Channel> { fatalError() }
    public func connect(
        host: String,
        port: Int,
        channelInitializer: @escaping (Channel) -> EventLoopFuture<Void>
    ) async throws -> NIOAsyncChannel<Void, Never> { fatalError() }
}

// Channel-level helpers that return EventLoopFuture (flagged).
public class SocketChannel: Channel {
    public func bind(to address: SocketAddress) -> EventLoopFuture<Void> { fatalError() }
    public func connect(to address: SocketAddress) -> EventLoopFuture<Void> { fatalError() }
}

// ── BAD: EventLoopFuture-based bootstrap bind ─────────────────────────────────

func badServerBindHostPort(bootstrap: ServerBootstrap) {
    _ = bootstrap.bind(host: "::1", port: 8080) // $ swift/nio-direct-channel-bind-connect
}

func badServerBindTo(bootstrap: ServerBootstrap, addr: SocketAddress) {
    _ = bootstrap.bind(to: addr) // $ swift/nio-direct-channel-bind-connect
}

// ── BAD: EventLoopFuture-based bootstrap connect ──────────────────────────────

func badClientConnectHostPort(bootstrap: ClientBootstrap) {
    _ = bootstrap.connect(host: "localhost", port: 8080) // $ swift/nio-direct-channel-bind-connect
}

func badClientConnectTo(bootstrap: ClientBootstrap, addr: SocketAddress) {
    _ = bootstrap.connect(to: addr) // $ swift/nio-direct-channel-bind-connect
}

// ── BAD: EventLoopFuture-based Channel bind/connect ───────────────────────────

func badChannelBind(ch: SocketChannel, addr: SocketAddress) {
    _ = ch.bind(to: addr) // $ swift/nio-direct-channel-bind-connect
}

func badChannelConnect(ch: SocketChannel, addr: SocketAddress) {
    _ = ch.connect(to: addr) // $ swift/nio-direct-channel-bind-connect
}

// ── GOOD: async NIOAsyncChannel-based API ─────────────────────────────────────

func goodServerBindAsync(bootstrap: ServerBootstrap) async throws {
    _ = try await bootstrap.bind(host: "::1", port: 8080) { _ in EventLoopFuture<Void>() }
}

func goodClientConnectAsync(bootstrap: ClientBootstrap) async throws {
    _ = try await bootstrap.connect(host: "localhost", port: 8080) { _ in EventLoopFuture<Void>() }
}
