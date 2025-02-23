//
//  TransactionController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 17/02/25.
//

import Fluent
import Vapor

struct TransactionController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) {
        let transaction = routes.grouped("transaction")

        transaction.group(
            UserToken.authenticator(),
            UserToken.guardMiddleware(throwing: Abort(.unauthorized, reason: "Unauthorized"))
        ) { route in
            route.get(use: self.getAllTransactions)
            route.post(use: self.createTransaction)

            route.group(":transaction_id") { route in
                route.post(use: self.skipOccurrence)
                route.patch(use: self.patchTransaction)
                route.delete(use: self.deleteTransaction)
            }
        }
    }

    @Sendable
    func getAllTransactions(request: Request) async throws(Abort) -> ResponseTransactions {
        guard
            var getTransaction = try? request.query.decode(GetTransaction.self)
        else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }
        getTransaction.startingDate = Calendar.current.startOfDay(for: getTransaction.startingDate)
        getTransaction.endingDate = Calendar.current.startOfDay(for: getTransaction.endingDate)

        guard
            let threeMonthsFromStartingDate = Calendar.current.date(byAdding: .month, value: 3, to: getTransaction.startingDate),
            getTransaction.endingDate > getTransaction.startingDate,
            getTransaction.endingDate <= threeMonthsFromStartingDate
        else {
            throw Abort(.unprocessableEntity, reason: "Invalid value(s)")
        }

        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(\.$id == userToken.userId).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        var responseTransaction: [ResponseTransaction] = []

        if getTransaction.onlyInclude == nil || getTransaction.onlyInclude == .unique {
            let uniqueTransactions: [UniqueTransaction]
            do {
                var request = try UniqueTransaction.query(on: request.db)
                    .filter(\.$user.$id == user.requireID())
                    .filter(\.$transactionDate >= getTransaction.startingDate)
                    .filter(\.$transactionDate <= getTransaction.endingDate)
                    .join(Category.self, on: \UniqueTransaction.$category.$id == \Category.$id)

                if let category = getTransaction.category {
                    request = request.filter(
                        Category.self, \Category.$name == category)
                }

                if let paymentType = getTransaction.paymentType {
                    request = request.filter(\.$paymentType == paymentType)
                }

                uniqueTransactions = try await request.all()
            } catch {
                throw Abort(.internalServerError, reason: "Unable to query database for transactions")
            }

            uniqueTransactions.forEach { value in
                responseTransaction.append(
                    .init(
                        id: try! value.requireID(),
                        transactionType: .unique,
                        title: value.title,
                        value: value.value,
                        paymentType: value.paymentType,
                        category: try! value.joined(Category.self).name,
                        transactionDate: value.transactionDate
                    )
                )
            }
        }

        if getTransaction.onlyInclude == nil || getTransaction.onlyInclude == .recurring {
            let recurringTransactions: [RecurringTransaction]
            do {
                var request = try RecurringTransaction.query(on: request.db)
                    .filter(\.$user.$id == user.requireID())
                    .filter(\.$startingDate <= getTransaction.endingDate)
                    .group(.or) { group in
                        group.filter(\.$endingDate == nil)
                        group.filter(\.$endingDate >= getTransaction.startingDate)
                    }
                    .join(Category.self, on: \RecurringTransaction.$category.$id == \Category.$id)

                if let category = getTransaction.category {
                    request = request.filter(Category.self, \Category.$name == category)
                }

                if let paymentType = getTransaction.paymentType {
                    request = request.filter(\.$paymentType == paymentType)
                }

                recurringTransactions = try await request.all()

                recurringTransactions.forEach { value in
                    var currentDate = value.startingDate

                    var currentLoop = 1
                    while (currentDate <= getTransaction.endingDate) && !(value.endingDate != nil && currentDate > value.endingDate!) {
                        if currentDate >= getTransaction.startingDate {
                            responseTransaction.append(
                                .init(
                                    id: try! value.requireID(),
                                    transactionType: .recurring,
                                    title: value.title,
                                    value: value.value,
                                    paymentType: value.paymentType,
                                    category: try! value.joined(Category.self).name,
                                    transactionDate: currentDate,
                                    transactionStatus: value.skippedOccurrences.contains(currentLoop) ? .skipped : .credited,
                                    occurrence: currentLoop,
                                    startingDate: value.startingDate,
                                    endingDate: value.endingDate
                                )
                            )
                        }

                        currentDate = Calendar.current.date(
                            byAdding: .month,
                            value: currentLoop,
                            to: value.startingDate
                        )!
                        currentLoop += 1
                    }
                }
            } catch {
                throw Abort(.internalServerError, reason: "Unable to query database for transactions")
            }
        }

        let total: Float = responseTransaction.reduce(0) { partialResult, transaction in
            if let status = transaction.transactionStatus, status == .skipped {
                return partialResult
            } else {
                return partialResult + transaction.value
            }
        }
        
        return .init(
            total: total,
            staringDate: getTransaction.startingDate,
            endingDate: getTransaction.endingDate,
            transactions: responseTransaction
        )
    }

    @Sendable
    func createTransaction(request: Request) async throws(Abort) -> Success {
        guard
            let transaction = try? request.content.decode(PostTransaction.self)
        else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }

        guard
            (try? PostTransaction.validate(content: request)) != nil
        else {
            throw Abort(.unprocessableEntity, reason: "Invalid value(s)")
        }

        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(\.$id == userToken.userId).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        var category: Category?
        do {
            category = try await Category.query(on: request.db).filter(\.$name == transaction.category).first()
        } catch {
            throw Abort(.internalServerError, reason: "Unable to fetch categories from the database")
        }

        do {
            if category == nil {
                category = Category(userId: try user.requireID(), name: transaction.category)
                try await category!.save(on: request.db)
            }
        } catch FluentError.idRequired {
            throw Abort(.unauthorized, reason: "Unauthorized")  // should never be reached
        } catch let error as DatabaseError where error.isConstraintFailure {
            throw Abort(.internalServerError, reason: "Something went wrong.", suggestedFixes: ["A category with that name already exists"])  // should never be reached
        } catch {
            throw Abort(.internalServerError, reason: "Unable to save new category to the database")
        }

        let transactionModel: any Transaction
        do {
            transactionModel = try transaction.toModel(user: user, category: category!)
        } catch {
            throw Abort(.internalServerError, reason: "Something went wrong.", suggestedFixes: ["Invalid user or category values"])  // should never be reached
        }

        do {
            try await transactionModel.create(on: request.db)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to save transaction to the database")
        }

        return Success()
    }

    @Sendable
    func patchTransaction(request: Request) async throws(Abort) -> Success {
        guard
            let patchTransaction = try? request.content.decode(PatchTransaction.self)
        else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }
        
        guard
            (try? PatchTransaction.validate(content: request)) != nil
        else {
            throw Abort(.unprocessableEntity, reason: "Invalid value(s)")
        }
        
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db)
                .filter(\.$id == userToken.userId)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }
        
        let transactionId = request.parameters.get("transaction_id", as: UUID.self)!
        
        let transaction: any Transaction
        
        if let uniqueTransaction = try? await UniqueTransaction.query(on: request.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$id == transactionId)
            .join(Category.self, on: \UniqueTransaction.$category.$id == \Category.$id)
            .first() {
            
            transaction = uniqueTransaction
        } else if let recurringTransaction = try? await RecurringTransaction.query(on: request.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$id == transactionId)
            .join(Category.self, on: \RecurringTransaction.$category.$id == \Category.$id)
            .first() {
            
            transaction = recurringTransaction
        } else {
            throw Abort(.notFound, reason: "Transaction not found")
        }
        
        if let title = patchTransaction.title {
            transaction.title = title
        }
        
        if let value = patchTransaction.value {
            transaction.value = value
        }
        
        if let paymentType = patchTransaction.paymentType {
            transaction.paymentType = paymentType
        }
        
        if let category = patchTransaction.category {
            var patchedCategory: Category?
            do {
                patchedCategory = try await Category.query(on: request.db).filter(\.$name == category).first()
            } catch {
                throw Abort(.internalServerError, reason: "Unable to fetch categories from the database")
            }
            
            do {
                if patchedCategory == nil {
                    // transaction could be casted to either UniqueTransaction or RecurringTransaction since both have this same uesr property
                    patchedCategory = Category(userId: (transaction as! UniqueTransaction).$user.id, name: category)
                    try await patchedCategory!.save(on: request.db)
                }
            } catch FluentError.idRequired {
                throw Abort(.unauthorized, reason: "Unauthorized")  // should never be reached
            } catch let error as DatabaseError where error.isConstraintFailure {
                throw Abort(.internalServerError, reason: "Something went wrong.", suggestedFixes: ["A category with that name already exists"])  // should never be reached
            } catch {
                throw Abort(.internalServerError, reason: "Unable to save new category to the database")
            }
            
            do {
                (transaction as! UniqueTransaction).$category.id = try patchedCategory!.requireID()
            } catch {
                throw Abort(.internalServerError, reason: "Unable to assign new category to transaction")
            }
        }
        
        if transaction is UniqueTransaction {
            if let transactionDate = patchTransaction.transactionDate {
                (transaction as! UniqueTransaction).transactionDate = transactionDate
            }
        } else if transaction is RecurringTransaction {
            if let startingDate = patchTransaction.startingDate {
                (transaction as! RecurringTransaction).startingDate = startingDate
            }
            
            if let endingDate = patchTransaction.endingDate {
                (transaction as! RecurringTransaction).endingDate = endingDate
            }
        }
        
        do {
            try await transaction.update(on: request.db)
        } catch {
            throw Abort(.internalServerError, reason: "Unable to update transaction")
        }
        
        return Success()
    }
    
    @Sendable
    func deleteTransaction(request: Request) async throws(Abort) -> Success {
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db)
                .filter(\.$id == userToken.userId)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }
        
        let transactionId = request.parameters.get("transaction_id", as: UUID.self)!
        
        if let uniqueTransaction = try? await UniqueTransaction.query(on: request.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$id == transactionId)
            .join(Category.self, on: \UniqueTransaction.$category.$id == \Category.$id)
            .first() {
            
            do {
                try await uniqueTransaction.delete(on: request.db)
            } catch {
                throw Abort(.internalServerError, reason: "Unable to remove transaction from database")
            }
        } else if let recurringTransaction = try? await RecurringTransaction.query(on: request.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$id == transactionId)
            .join(Category.self, on: \RecurringTransaction.$category.$id == \Category.$id)
            .first() {
            
            do {
                try await recurringTransaction.delete(on: request.db)
            } catch {
                throw Abort(.internalServerError, reason: "Unable to remove transaction from database")
            }
        } else {
            throw Abort(.notFound, reason: "Transaction not found")
        }
        
        return Success()
    }
    
    @Sendable
    func skipOccurrence(request: Request) async throws(Abort) -> Success {
        guard
            let skipTransaction = try? request.content.decode(PostSkipTransaction.self)
        else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }
        
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db)
                .filter(\.$id == userToken.userId)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }
        
        let transactionId = request.parameters.get("transaction_id", as: UUID.self)!

        if let recurringTransaction = try? await RecurringTransaction.query(on: request.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$id == transactionId)
            .first() {
            
            if skipTransaction.action == .skip {
                recurringTransaction.skippedOccurrences.append(skipTransaction.occurrence)
            } else {
                if let index = recurringTransaction.skippedOccurrences.firstIndex(of: skipTransaction.occurrence) {
                    recurringTransaction.skippedOccurrences.remove(at: index)
                }
            }
            
            do {
                try await recurringTransaction.update(on: request.db)
            } catch {
                throw Abort(.internalServerError, reason: "Unable to update transaction")
            }
        } else {
            throw Abort(.notFound, reason: "Transaction not found")
        }
        
        return Success()
    }
}
