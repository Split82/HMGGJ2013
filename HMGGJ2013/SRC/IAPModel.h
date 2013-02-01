//
//  IAPModel.h
//  Escapology
//
//  Created by Loki on 8/27/12.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


extern NSString * const IAPModelUnhandledRestorePreviousPurchaseOfUndoCompletedNotification;

@interface IAPModel : NSObject<SKPaymentTransactionObserver, SKProductsRequestDelegate>

typedef void (^BuyProductCompletionHandler)(NSError *error);
typedef void (^LoadProductsCompletionHandler)(NSError *error);
typedef void (^RestorePreviousPurchasesCompletionHandler)(NSError *error);

+ (IAPModel*)sharedIAPModel;

- (BOOL)isIAPEnabled;

// error codes:
// 1 - request already in progress
// 2 - transaction was canceled
// 3 - transaction failed
// 4 - product not loaded
// 5 - loading products failed
- (void)buyUndoRedoProductWithCompletionHandler:(BuyProductCompletionHandler)completionHandler;
- (void)cancelBuyingProduct;

- (void)loadProductsRequestWithCompletionHandler:(LoadProductsCompletionHandler)completionHandler;
@property (nonatomic, readonly, getter = isLoadingProducts) BOOL loadingProducts;
- (void)cancelLoadingProductsRequest;


- (void)restorePreviousPurchasesWithCompletionHandler:(RestorePreviousPurchasesCompletionHandler)completionHandler;
@property (nonatomic, readonly, getter = isRestoringPreviousPurchases) BOOL restoringPreviousPurchases;
- (void)cancelRestoringPreviousPurchases;

@property (nonatomic, readonly, getter = isUndoPurchased) BOOL undoPurchased;
@property (nonatomic, readonly, retain) SKProduct *undoProduct;

@end