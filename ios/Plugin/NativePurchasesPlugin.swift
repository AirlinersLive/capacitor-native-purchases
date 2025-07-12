import Foundation
import Capacitor
import StoreKit

@objc(NativePurchasesPlugin)
public class NativePurchasesPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativePurchasesPlugin"
    public let jsName = "NativePurchases"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isBillingSupported", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchaseProduct", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restorePurchases", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getProducts", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getProduct", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPluginVersion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getLatestSignedTransaction", returnType: CAPPluginReturnPromise)
    ]

    private let PLUGIN_VERSION = "0.0.25"

    @objc func getPluginVersion(_ call: CAPPluginCall) {
        call.resolve(["version": self.PLUGIN_VERSION])
    }

    @objc func isBillingSupported(_ call: CAPPluginCall) {
        if #available(iOS 17, *) {
            call.resolve([
                "isBillingSupported": true
            ])
        } else {
            call.resolve([
                "isBillingSupported": false
            ])
        }
    }

    @objc func purchaseProduct(_ call: CAPPluginCall) {
        if #available(iOS 17, *) {
            print("purchaseProduct")
            let productIdentifier = call.getString("productIdentifier", "")
            let quantity = call.getInt("quantity", 1)
            if productIdentifier.isEmpty {
                call.reject("productIdentifier is Empty, give an id")
                return
            }

            Task {
                do {
                    let products = try await Product.products(for: [productIdentifier])
                    guard let product = products.first else {
                        call.reject("Cannot find product for id \(productIdentifier)")
                        return
                    }
                    var purchaseOptions = Set<Product.PurchaseOption>()
                    purchaseOptions.insert(Product.PurchaseOption.quantity(quantity))
                    let result = try await product.purchase(options: purchaseOptions)
                    print("purchaseProduct result \(result)")
                    switch result {
                    case let .success(verificationResult):
                        // This is VerificationResult<Transaction>
                        let jwt = verificationResult.jwsRepresentation
                        let transaction = try verificationResult.payloadValue

                        await transaction.finish()

                        var transactionData: [String: Any] = [
                            "transactionId": transaction.id,
                            "originalTransactionId": transaction.originalID,
                            "productId": transaction.productID,
                            "purchaseDate": transaction.purchaseDate.timeIntervalSince1970 * 1000,
                            "originalPurchaseDate": transaction.originalPurchaseDate.timeIntervalSince1970 * 1000,
                            "environment": transaction.environment.rawValue,
                            "quantity": transaction.purchasedQuantity,
                            "signedDate": transaction.signedDate.timeIntervalSince1970 * 1000,
                            "transactionReason": transaction.reason.rawValue,
                            "price": transaction.price ?? 0,
                            "currency": transaction.currency?.identifier ?? "",
                            "subscriptionGroupId": transaction.subscriptionGroupID ?? "",
                            "webOrderLineItemId": transaction.webOrderLineItemID ?? "",
                            //"appTransactionId": transaction.appTransactionID,
                            "bundleId": transaction.appBundleID,
                            "inAppOwnershipType": transaction.ownershipType.rawValue,
                            "jwt": jwt
                        ]
                        if let expirationDate = transaction.expirationDate {
                            transactionData["expiresDate"] = expirationDate.timeIntervalSince1970 * 1000
                        }
                        if transaction.productType == .autoRenewable {
                            transactionData["type"] = "Auto-Renewable Subscription"
                        } else if transaction.productType == .nonRenewable {
                            transactionData["type"] = "Non-Renewable Subscription"
                        } else if transaction.productType == .consumable {
                            transactionData["type"] = "Consumable"
                        } else if transaction.productType == .nonConsumable {
                            transactionData["type"] = "Non-Consumable"
                        }
                        call.resolve(transactionData)
                    case .pending:
                        call.reject("Transaction pending")
                    case .userCancelled:
                        call.reject("User cancelled")
                    @unknown default:
                        call.reject("Unknown purchase result")
                    }
                } catch {
                    print(error)
                    call.reject(error.localizedDescription)
                }
            }
        } else {
            print("Not implemented under iOS 17")
            call.reject("Not implemented under iOS 17")
        }
    }

    @objc func restorePurchases(_ call: CAPPluginCall) {
        if #available(iOS 17.0, *) {
            print("restorePurchases")
            DispatchQueue.global().async {
                Task {
                    do {
                        try await AppStore.sync()
                        for transaction in SKPaymentQueue.default().transactions {
                            SKPaymentQueue.default().finishTransaction(transaction)
                        }
                        call.resolve()
                    } catch {
                        call.reject(error.localizedDescription)
                    }
                }
            }
        } else {
            print("Not implemented under iOS 17")
            call.reject("Not implemented under iOS 17")
        }
    }

    @objc func getProducts(_ call: CAPPluginCall) {
        if #available(iOS 17.0, *) {
            let productIdentifiers = call.getArray("productIdentifiers", String.self) ?? []
            DispatchQueue.global().async {
                Task {
                    do {
                        let products = try await Product.products(for: productIdentifiers)
                        let productsJson: [[String: Any]] = products.map { $0.dictionary }
                        call.resolve([
                            "products": productsJson
                        ])
                    } catch {
                        print(error)
                        call.reject(error.localizedDescription)
                    }
                }
            }
        } else {
            print("Not implemented under iOS 17")
            call.reject("Not implemented under iOS 17")
        }
    }

    @objc func getProduct(_ call: CAPPluginCall) {
        if #available(iOS 17.0, *) {
            let productIdentifier = call.getString("productIdentifier") ?? ""
            if productIdentifier.isEmpty {
                call.reject("productIdentifier is empty")
                return
            }

            DispatchQueue.global().async {
                Task {
                    do {
                        let products = try await Product.products(for: [productIdentifier])
                        if let product = products.first {
                            let productJson = product.dictionary
                            call.resolve(["product": productJson])
                        } else {
                            call.reject("Product not found")
                        }
                    } catch {
                        print(error)
                        call.reject(error.localizedDescription)
                    }
                }
            }
        } else {
            print("Not implemented under iOS 17")
            call.reject("Not implemented under iOS 17")
        }
    }

    @objc func getLatestSignedTransaction(_ call: CAPPluginCall) {
        if #available(iOS 17.0, *) {
            Task {
                do {
                    for await verificationResult in Transaction.currentEntitlements {
                        let jwt = verificationResult.jwsRepresentation
                        let transaction = try verificationResult.payloadValue
                        var transactionData: [String: Any] = [
                            "transactionId": transaction.id,
                            // ... (add any other fields you want) ...
                            "jwt": jwt
                        ]
                        call.resolve(transactionData)
                        return
                    }
                    call.reject("No StoreKit 2 transactions found")
                } catch {
                    call.reject("Failed to get signed transaction: \(error.localizedDescription)")
                }
            }
        } else {
            call.reject("StoreKit 2 JWT is only available on iOS 17+")
        }
    }
}

