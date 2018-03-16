//
//  AssetDataManager.swift
//  loopr-ios
//
//  Created by Xiao Dou Dou on 2/2/18.
//  Copyright © 2018 Loopring. All rights reserved.
//

import Foundation
import SwiftyJSON
import BigInt

class AssetDataManager {

    static let shared = AssetDataManager()
    
    private var totalAsset: Double
    private var assets: [Asset]
    private var tokens: [Token]
    private var transactions: [Transaction]
    
    private init() {
        self.assets = []
        self.tokens = []
        self.transactions = []
        self.totalAsset = 0
        self.loadTokensFromJson()
    }
    
    func getTokens() -> [Token] {
        return tokens
    }
    
    func getTotalAsset() -> Double {
        return totalAsset
    }
    
    func getAssets(enable: Bool? = nil) -> [Asset] {
        guard let enable = enable else {
            return self.assets
        }
        return assets.filter { (asset) -> Bool in
            asset.enable == enable
        }
    }

    func getTransactions(txStatuses: [Transaction.TxStatus]? = nil) -> [Transaction] {
        guard let txStatuses = txStatuses else {
            return self.transactions
        }
        return transactions.filter { (transaction) -> Bool in
            txStatuses.contains(transaction.status)
        }
    }
    
    func getTokenBySymbol(_ symbol: String) -> Token? {
        var result: Token? = nil
        for case let token in tokens where token.symbol.lowercased() == symbol.lowercased() {
            result = token
            break
        }
        return result
    }
    
    func exchange(at sourceIndex: Int, to destinationIndex: Int) {
        if destinationIndex < assets.count && sourceIndex < assets.count {
            assets.swapAt(sourceIndex, destinationIndex)
        }
    }
    
    // MARK: whether stop method is useful?
    func startGetBalance(_ owner: String) {
        LoopringSocketIORequest.getBalance(owner: owner)
    }
    
    // load tokens esp. their names from json file to avoid http request
    func loadTokensFromJson() {
        if let path = Bundle.main.path(forResource: "tokens", ofType: "json") {
            let jsonString = try? String(contentsOfFile: path, encoding: String.Encoding.utf8)
            let json = JSON(parseJSON: jsonString!)
            for subJson in json.arrayValue {
                let token = Token(json: subJson)
                tokens.append(token)
            }
        }
    }
    
    func getAmount(of symbol: String, from gweiAmount: String, to precision: Int = 4) -> Double? {
        var result: Double? = nil
        if gweiAmount.lowercased().starts(with: "0x") {
            let range = gweiAmount.lowercased().range(of: "0x")
            let hexString = gweiAmount.suffix(from: range!.upperBound)
            let decString = BigUInt(hexString, radix: 16)!.description
            return getAmount(of: symbol, from: decString, to: precision)
        } else if let token = getTokenBySymbol(symbol) {
            var amount = gweiAmount
            let offset = precision - token.decimals
            var index = amount.index(amount.endIndex, offsetBy: offset)
            amount.removeSubrange(index...)
            index = amount.index(amount.endIndex, offsetBy: -precision)
            amount.insert(".", at: index)
            result = Double(amount)
        }
        return result
    }
    
    func getTransactionsFromServer(asset: Asset) {
        
        transactions = []
        let ownerx = "0x48ff2269e58a373120FFdBBdEE3FBceA854AC30A"
        
//        if let owner = AppWalletDataManager.shared.getCurrentAppWallet()?.address {
            LoopringAPIRequest.getTransactions(owner: ownerx, symbol: asset.symbol, thxHash: nil, completionHandler: { (transactions, error) in
                guard error == nil && transactions != nil else {
                    return
                }
                for transaction in transactions! {
                    if let value = self.getAmount(of: transaction.symbol, from: transaction.value) {
                        if let price = PriceQuoteDataManager.shared.getPriceBySymbol(of: asset.symbol) {
                            transaction.value = value.description
                            transaction.display = value * price
                            self.transactions.append(transaction)
                        }
                    }
                }
            })
//        }
    }
    
    // this func should be called every 10 secs when emitted
    func onBalanceResponse(json: JSON) {
        
        assets = []
        totalAsset = 0
        for subJson in json["tokens"].arrayValue {
            let asset = Asset(json: subJson)
            if let balance = getAmount(of: asset.symbol, from: asset.balance) {
                if let price = PriceQuoteDataManager.shared.getPriceBySymbol(of: asset.symbol) {
                    asset.balance = balance.description
                    asset.display = balance * price
                    asset.name = getTokenBySymbol(asset.symbol)?.source ?? "unknown token"
                    totalAsset += asset.display
                    assets.append(asset)
                }
            }
        }
    }
}
