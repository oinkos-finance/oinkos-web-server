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
            UserToken.guardMiddleware(
                throwing: Abort(.unauthorized, reason: "Unauthorized"))
        ) { route in
            route.get(use: self.getAllTransactions)
            route.post(use: self.createTransaction)
        }

    }

    @Sendable
    func getAllTransactions(request: Request) async throws(Abort) -> ResponseTransactions {
        guard
            var getTransaction = try? request.query.decode(GetTransaction.self)
        else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }
        getTransaction.startingDate = Calendar.current.startOfDay(
            for: getTransaction.startingDate)
        getTransaction.endingDate = Calendar.current.startOfDay(
            for: getTransaction.endingDate)

        guard
            let threeMonthsFromStartingDate = Calendar.current.date(
                byAdding: .month, value: 3, to: getTransaction.startingDate),
            getTransaction.endingDate > getTransaction.startingDate,
            getTransaction.endingDate <= threeMonthsFromStartingDate
        else {
            throw Abort(.unprocessableEntity, reason: "Invalid value(s)")
        }

        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(
                \.$id == userToken.userId
            ).first()
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
                    .join(
                        Category.self,
                        on: \UniqueTransaction.$category.$id == \Category.$id)

                if let category = getTransaction.category {
                    request = request.filter(
                        Category.self, \Category.$name == category)
                }

                if let paymentType = getTransaction.paymentType {
                    request = request.filter(\.$paymentType == paymentType)
                }

                uniqueTransactions = try await request.all()
            } catch {
                throw Abort(
                    .internalServerError,
                    reason: "Unable to query database for transactions")
            }

            uniqueTransactions.forEach { value in
                responseTransaction.append(
                    .init(
                        transactionType: .unique,
                        transactionStatus: .credited,
                        occurrence: 1,
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
                    .group(.or) { group in
                        group.filter(\.$endingDate == nil)
                        group.filter(
                            \.$endingDate <= getTransaction.startingDate)
                    }
                    .join(
                        Category.self,
                        on: \RecurringTransaction.$category.$id == \Category.$id
                    )

                if let category = getTransaction.category {
                    request = request.filter(
                        Category.self, \Category.$name == category)
                }

                if let paymentType = getTransaction.paymentType {
                    request = request.filter(\.$paymentType == paymentType)
                }

                recurringTransactions = try await request.all()

                recurringTransactions.forEach { value in
                    var currentDate = value.startingDate

                    var currentLoop = 1
                    while (currentDate <= getTransaction.endingDate)
                        && !(value.endingDate != nil
                            && currentDate >= value.endingDate!)
                    {
                        if currentDate >= getTransaction.startingDate {
                            responseTransaction.append(
                                .init(
                                    transactionType: .recurring,
                                    transactionStatus: value.skippedOccurrences
                                        .contains(currentLoop)
                                        ? .skipped : .credited,
                                    occurrence: currentLoop,
                                    title: value.title,
                                    value: value.value,
                                    paymentType: value.paymentType,
                                    category: try! value.joined(Category.self)
                                        .name,
                                    transactionDate: currentDate
                                )
                            )
                        }

                        currentDate = Calendar.current.date(
                            byAdding: .month,
                            value: currentLoop,
                            to: value.startingDate
                        )!
                        currentLoop += 1

                        print(currentDate.ISO8601Format())
                    }
                }
            } catch {
                throw Abort(
                    .internalServerError,
                    reason: "Unable to query database for transactions"
                )
            }
        }

        let responseTranscations: ResponseTransactions = .init(
            staringDate: getTransaction.startingDate,
            endingDate: getTransaction.endingDate,
            transactions: responseTransaction
        )

        return responseTranscations
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
            let user = try? await User.query(on: request.db).filter(
                \.$id == userToken.userId
            ).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        var category: Category?
        do {
            category = try await Category.query(on: request.db).filter(
                \.$name == transaction.category
            ).first()
        } catch {
            throw Abort(
                .internalServerError,
                reason: "Unable to fetch categories from the database")
        }

        do {
            if category == nil {
                category = Category(
                    userId: try user.requireID(), name: transaction.category)
                try await category!.save(on: request.db)
            }
        } catch FluentError.idRequired {
            throw Abort(.unauthorized, reason: "Unauthorized")  // should never be reached
        } catch let error as DatabaseError where error.isConstraintFailure {
            print(error)
            throw Abort(
                .internalServerError, reason: "Something went wrong.", suggestedFixes: ["A category with that name already exists"])  // should never be reached
        } catch {
            throw Abort(
                .internalServerError,
                reason: "Unable to save new category to the database")
        }

        let transactionModel: any Transaction
        do {
            transactionModel = try transaction.toModel(
                user: user, category: category!)
        } catch {
            throw Abort(
                .internalServerError, reason: "Something went wrong.", suggestedFixes: ["Invalid user or category values"])  // should never be reached
        }

        do {
            try await transactionModel.save(on: request.db)
        } catch {
            throw Abort(
                .internalServerError,
                reason: "Failed to save transaction to the database")
        }

        return Success()
    }
}
