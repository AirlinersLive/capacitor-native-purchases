import { WebPlugin } from "@capacitor/core";

import type { NativePurchasesPlugin, Product, Transaction } from "./definitions";

export class NativePurchasesWeb
  extends WebPlugin
  implements NativePurchasesPlugin
{
  async restorePurchases(): Promise<void> {
    console.error("restorePurchases only mocked in web");
  }

  async getProducts(options: {
    productIdentifiers: string[];
  }): Promise<{ products: Product[] }> {
    console.error("getProducts only mocked in web " + options);
    return { products: [] };
  }

  async getProduct(options: {
    productIdentifier: string;
  }): Promise<{ product: Product }> {
    console.error("getProduct only mocked in web " + options);
    return { product: {} as any };
  }

  async purchaseProduct(options: {
    productIdentifier: string;
    planIdentifier?: string;
    quantity?: number;
  }): Promise<Transaction> {
    console.error("purchaseProduct only mocked in web" + options);
    return {
      transactionId: "mock-transaction-id",
    };
  }

  async isBillingSupported(): Promise<{ isBillingSupported: boolean }> {
    console.error("isBillingSupported only mocked in web");
    return { isBillingSupported: false };
  }
  
  async getPluginVersion(): Promise<{ version: string }> {
    console.warn("Cannot get plugin version in web");
    return { version: "default" };
  }

  async getLatestSignedTransaction(): Promise<{ jwt: string }> {
    console.error("getLatestSignedTransaction only mocked in web");
    return { jwt: "mock-jwt-token" };
  }
}
