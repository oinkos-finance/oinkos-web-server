import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    try app.register(collection: SignUpController())
    try app.register(collection: LogInController())
    try app.register(collection: TransactionController())
    try app.register(collection: CategoryController())
}
