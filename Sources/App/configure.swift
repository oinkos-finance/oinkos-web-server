import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("oinkos.sqlite")), as: .sqlite)

    let key = ES256PrivateKey()
    await app.jwt.keys.add(ecdsa: key)
    
    app.migrations.add(CreateUser())

    try routes(app)
}
