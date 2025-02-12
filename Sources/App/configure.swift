import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("oinkos.sqlite")), as: .sqlite)

    let key = ES256PrivateKey()
    await app.jwt.keys.add(ecdsa: key)
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())

    try routes(app)
}
