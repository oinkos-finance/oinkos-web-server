import Fluent
import FluentSQLiteDriver
import JWT
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("oinkos.sqlite")), as: .sqlite)

    guard let keyString = Environment.get("PRIVATE_KEY") else { fatalError("Could not find PRIVATE_KEY environment variable") }

    let key = try ES256PrivateKey(pem: keyString)

    await app.jwt.keys.add(ecdsa: key)

    app.migrations.add(CreateUser())
    app.migrations.add(CreatePaymentType())
    app.migrations.add(CreateRecurringTransaction())

    try routes(app)
}
