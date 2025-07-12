//
//  Extensions.swift
//  CapgoCapacitorPurchases
//
//  Created by Martin DONADIEU on 2023-08-08.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
extension Product {

    var dictionary: [String: Any] {
        //        /**
        //         * Currency code for price and original price.
        //         */
        //        readonly currencyCode: string;
        //        /**
        //         * Currency symbol for price and original price.
        //         */
        //        readonly currencySymbol: string;
        //        /**
        //         * Boolean indicating if the product is sharable with family
        //         */
        //        readonly isFamilyShareable: boolean;
        //        /**
        //         * Group identifier for the product.
        //         */
        //        readonly subscriptionGroupIdentifier: string;
        //        /**
        //         * The Product subcription group identifier.
        //         */
        //        readonly subscriptionPeriod: SubscriptionPeriod;
        //        /**
        //         * The Product introductory Price.
        //         */
        //        readonly introductoryPrice: SKProductDiscount | null;
        //        /**
        //         * The Product discounts list.
        //         */
        //        readonly discounts: SKProductDiscount[];
        var productDict: [String: Any] = [
            "identifier": self.id,
            "description": self.description,
            "title": self.displayName,
            "price": self.price,
            "priceString": self.displayPrice,
            "currencyCode": self.priceFormatStyle.currencyCode,
            "currencySymbol": self.priceFormatStyle.currencySymbol ?? "",
            "isFamilyShareable": self.isFamilyShareable
        ]
        
        // Add subscription group identifier if available
        if let subscriptionGroupID = self.subscription?.subscriptionGroupID {
            productDict["subscriptionGroupIdentifier"] = subscriptionGroupID
        } else {
            productDict["subscriptionGroupIdentifier"] = ""
        }
        
        // Add subscription period if available
        if let subscriptionPeriod = self.subscription?.subscriptionPeriod {
            productDict["subscriptionPeriod"] = [
                "numberOfUnits": subscriptionPeriod.value,
                "unit": subscriptionPeriod.unit.rawValue
            ]
        }
        
        // Add introductory price if available
        if let introOffer = self.subscription?.introductoryOffer {
            productDict["introductoryPrice"] = [
                "identifier": introOffer.id ?? "",
                "type": introOffer.type.rawValue,
                "price": introOffer.price,
                "priceString": introOffer.displayPrice,
                "currencySymbol": introOffer.priceFormatStyle.currencySymbol ?? "",
                "currencyCode": introOffer.priceFormatStyle.currencyCode,
                "paymentMode": introOffer.paymentMode.rawValue,
                "numberOfPeriods": introOffer.periodCount,
                "subscriptionPeriod": [
                    "numberOfUnits": introOffer.period.value,
                    "unit": introOffer.period.unit.rawValue
                ]
            ]
        } else {
            productDict["introductoryPrice"] = NSNull()
        }
        
        // Add promotional offers (discounts)
        var discounts: [[String: Any]] = []
        if let promotionalOffers = self.subscription?.promotionalOffers {
            for offer in promotionalOffers {
                discounts.append([
                    "identifier": offer.id,
                    "type": offer.type.rawValue,
                    "price": offer.price,
                    "priceString": offer.displayPrice,
                    "currencySymbol": offer.priceFormatStyle.currencySymbol ?? "",
                    "currencyCode": offer.priceFormatStyle.currencyCode,
                    "paymentMode": offer.paymentMode.rawValue,
                    "numberOfPeriods": offer.periodCount,
                    "subscriptionPeriod": [
                        "numberOfUnits": offer.period.value,
                        "unit": offer.period.unit.rawValue
                    ]
                ])
            }
        }
        productDict["discounts"] = discounts
        
        return productDict
    }
}
