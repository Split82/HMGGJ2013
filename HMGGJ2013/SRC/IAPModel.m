//
//  IAPModel.m
//  Escapology
//
//  Created by Loki on 8/27/12.
//
//

#import "IAPModel.h"

#define GAME_MODEL_ERROR_DOMAIN @"GameModelErrorDomain"

NSString *kDefaultsUndoPasswordKey = @"initRTCacheKey"; // :D :D :D
NSString *kUndoProductId = @"UndoRedo";

NSString * const IAPModelUnhandledRestorePreviousPurchaseOfUndoCompletedNotification = @"IAPModelUnhandledRestorePreviousPurchaseOfUndoCompletedNotification";


@interface IAPModel()  

@property (nonatomic, copy) BuyProductCompletionHandler buyProductCompletionHandler;
@property (nonatomic, retain) SKProduct *undoProduct;
@property (nonatomic, copy) RestorePreviousPurchasesCompletionHandler restorePreviousPurchasesCompletionHandler;
@property (nonatomic, copy) LoadProductsCompletionHandler loadProductsCompletionHandler;
@property (nonatomic, retain) SKPayment *currentPayment;

- (void)completeTransaction:(SKPaymentTransaction*)transaction;
- (void)failedTransaction:(SKPaymentTransaction*)transaction;
- (void)restoreTransaction:(SKPaymentTransaction*)transaction;

@end


@implementation IAPModel

@synthesize loadingProducts;
@synthesize restoringPreviousPurchases;
@synthesize undoPurchased;
@synthesize undoProduct = _undoRedoProduct;
@synthesize buyProductCompletionHandler = _buyProductCompletionHandler;
@synthesize restorePreviousPurchasesCompletionHandler = _restorePreviousPurchasesCompletionHandler;
@synthesize loadProductsCompletionHandler = _loadProductsCompletionHandler;
@synthesize currentPayment = _currentPayment;

#pragma mark - shared instance

static IAPModel *sharedIAPModel = nil;

- (NSError*)errorWithDescription:(NSString*)description errorCode:(int)errorCode {
    
    return [NSError errorWithDomain:@"lol" code:errorCode userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
}

+ (IAPModel*)sharedIAPModel {
    if (sharedIAPModel == nil ) {
        sharedIAPModel = [[self alloc] init];
    }
    return sharedIAPModel;
}

#pragma mark - init

- (id)init {
    
    if (self = [super init]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        undoPurchased = ([defaults objectForKey:kDefaultsUndoPasswordKey] ? YES : NO);
        
        loadingProducts = NO;
        restoringPreviousPurchases = NO;
        self.currentPayment = nil;
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    
    return self;
}

#pragma mark - model public interface

- (void)buyProduct:(SKProduct*)product withCompletionHandler:(BuyProductCompletionHandler)completionHandler {
    
    if (self.currentPayment) {
        
        completionHandler([self errorWithDescription:NSLocalizedString(@"Request already in progress.", @"") errorCode:1]);
        return;
    }
    
    self.buyProductCompletionHandler = completionHandler;
    
    self.currentPayment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:self.currentPayment];
}

- (void)cancelBuyingProduct {
    
    self.buyProductCompletionHandler = nil;
    self.currentPayment = nil;
}

- (void)loadProductsRequestWithCompletionHandler:(LoadProductsCompletionHandler)completionHandler {
    
    if (loadingProducts) {
        
        completionHandler([self errorWithDescription:NSLocalizedString(@"Request already in progress.", @"") errorCode:1]);
        return;
    }
    else if (self.undoProduct) {
        
        completionHandler(nil);
    }
    else {
        
        loadingProducts = YES;
        self.loadProductsCompletionHandler = completionHandler;
        
        
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kUndoProductId]];
        request.delegate = self;
        [request start];
    }
}

- (void)cancelLoadingProductsRequest {
    
    loadingProducts = NO;
    self.loadProductsCompletionHandler = nil;
}

- (BOOL)isIAPEnabled {
    
    return [SKPaymentQueue canMakePayments];
}

- (void)restorePreviousPurchasesWithCompletionHandler:(RestorePreviousPurchasesCompletionHandler)completionHandler {
    
    if (restoringPreviousPurchases) {
        
        completionHandler([self errorWithDescription:NSLocalizedString(@"Request already in progress.", @"") errorCode:1]);
        return;
    }
    
    restoringPreviousPurchases = YES;
    self.restorePreviousPurchasesCompletionHandler = completionHandler;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)cancelRestoringPreviousPurchases {
    
    restoringPreviousPurchases = NO;
    self.restorePreviousPurchasesCompletionHandler = nil;
}

- (void)buyUndoRedoProductWithCompletionHandler:(BuyProductCompletionHandler)completionHandler {
    
    if (self.isUndoPurchased) {
        
        completionHandler(nil);
        return;
    }
    
    if (self.undoProduct == nil) {
        
        BuyProductCompletionHandler copiedCompletionHander = [completionHandler copy];        
        [self loadProductsRequestWithCompletionHandler:^(NSError *error) {
            
            if (error) {
                
                copiedCompletionHander([self errorWithDescription:NSLocalizedString(@"Products could not be loaded.", @"") errorCode:1]);
            }
            else if (!self.undoProduct) {
                
                copiedCompletionHander([self errorWithDescription:NSLocalizedString(@"Products could not be recognized.", @"") errorCode:2] );
            }
            else {
                [self buyProduct:self.undoProduct withCompletionHandler:copiedCompletionHander];
            }
        }];
    }
    else {
        
        [self buyProduct:self.undoProduct withCompletionHandler:completionHandler];
    }
}

#pragma mark - process transaction

- (void)completeTransaction:(SKPaymentTransaction*)transaction {
    
    BOOL transactionIsForCurrentPayment = (self.currentPayment && [self.currentPayment.productIdentifier isEqualToString:transaction.payment.productIdentifier]);
    
    if ([transaction.payment.productIdentifier isEqualToString:kUndoProductId]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"0xF3B4" forKey:kDefaultsUndoPasswordKey];
        [defaults synchronize];
        undoPurchased = true;
        
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        
        if (transactionIsForCurrentPayment) {
            
            self.currentPayment = nil;
            self.buyProductCompletionHandler(nil);
        }
        else {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:IAPModelUnhandledRestorePreviousPurchaseOfUndoCompletedNotification object:nil];
        }
        
    }
}

- (void)restoreTransaction:(SKPaymentTransaction*)transaction {
    
    if ([transaction.payment.productIdentifier isEqualToString:kUndoProductId]) {
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"0xEA23" forKey:kDefaultsUndoPasswordKey];
        [defaults synchronize];
        undoPurchased = true;
        
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        
        if (restoringPreviousPurchases == NO) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:IAPModelUnhandledRestorePreviousPurchaseOfUndoCompletedNotification object:nil];
        }
    }
}

- (void)failedTransaction:(SKPaymentTransaction*)transaction {
    
    BOOL transactionIsForCurrentPayment = (self.currentPayment && [self.currentPayment.productIdentifier isEqualToString:transaction.payment.productIdentifier]);
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    if (transaction.error.code != SKErrorPaymentCancelled) {
        
        if (transactionIsForCurrentPayment) {
            
            self.currentPayment = nil;
            self.buyProductCompletionHandler([self errorWithDescription:NSLocalizedString(@"Transaction failed.", @"") errorCode:2]);
        }
    }
    else {
        
        if (transactionIsForCurrentPayment) {
            
            self.currentPayment = nil;
            self.buyProductCompletionHandler([self errorWithDescription:NSLocalizedString(@"Transaction canceled.", @"") errorCode:3]);
        }
    }
    
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    if ([response.invalidProductIdentifiers count] > 0) {
        
        if (loadingProducts) {
            
            loadingProducts = NO;
            self.loadProductsCompletionHandler([self errorWithDescription:NSLocalizedString(@"Loading products failed.", @"") errorCode:5]);
        }
        
        return;
    }
    
    for (SKProduct *product in response.products) {
        
        if ([product.productIdentifier isEqualToString:kUndoProductId]) {
            
            self.undoProduct = product;
        }
    }
    
    if (loadingProducts) {
        
        loadingProducts = NO;
        self.loadProductsCompletionHandler(nil);
    }
}

#pragma mark - SKPaymentTransactionObserver protocol

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    
    if (restoringPreviousPurchases) {
        
        restoringPreviousPurchases = NO;
        self.restorePreviousPurchasesCompletionHandler([self errorWithDescription:NSLocalizedString(@"Transaction canceled.", @"") errorCode:3]);
    }
}


- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    
    if (restoringPreviousPurchases) {
        
        restoringPreviousPurchases = NO;
        self.restorePreviousPurchasesCompletionHandler(undoPurchased ? nil : [self errorWithDescription:NSLocalizedString(@"No previous purchases to restore.", @"") errorCode:3]);
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    
    for (SKPaymentTransaction *transaction in transactions) {
        
        switch (transaction.transactionState) {
                
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}


@end

