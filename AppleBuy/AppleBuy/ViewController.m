//
//  ViewController.m
//  AppleBuy
//
//  Created by 王晓栋 on 2017/1/20.
//  Copyright © 2017年 王晓栋. All rights reserved.
//

#import "ViewController.h"
#import <StoreKit/StoreKit.h>
#define PRODUCTID @"" // 商品ID(请填写你商品的id)

@interface ViewController ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
- (IBAction)buy:(UIButton *)sender;


@property(nonatomic,strong)SKPayment *payment;
@property(nonatomic,strong)SKMutablePayment *skMutablePaymet;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}




- (IBAction)buy:(UIButton *)sender {
    //判断是否可进行支付
    if ([SKPaymentQueue canMakePayments]) {
        [self requestProductData:PRODUCTID];
    } else {
        NSLog(@"不允许程序内付费");
    }
    
}
- (void)requestProductData:(NSString *)type{
    //根据商品ID查找商品信息
    NSArray *product = [NSArray arrayWithObjects:type, nil];
    NSSet *set = [NSSet setWithArray:product];
    //创建SKProductsRequest对象，用想要出售的商品的标识来初始化， 然后附加上对应的委托对象。
    //该请求的响应包含了可用商品的本地化信息。
    SKProductsRequest *request = [[SKProductsRequest alloc]initWithProductIdentifiers:set];
    request.delegate = self;
    [request start];
}
#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    //接受商品信息
    NSArray *products =  response.products;
    if ([products count] == 0) {
        return;
    }
    // SKProduct对象包含了在App store 上注册的商品本地化信息
    SKProduct *storeProduct = nil;
    for (SKProduct *product in products) {
        if ([product.productIdentifier isEqualToString:PRODUCTID]) {
            storeProduct = product;
        }
    }
    //创建一个支付对象，并放到队列中
    self.skMutablePaymet = [SKMutablePayment paymentWithProduct:storeProduct];
    //设置购买的数量
    self.skMutablePaymet.quantity = 1;
    [self.skMutablePaymet requestData];
    [[SKPaymentQueue defaultQueue] addPayment:self.skMutablePaymet];
    
}
#pragma mark SKRequestDelegate
//请求成功
- (void)requestDidFinish:(SKRequest *)request{
    
    NSLog(@"请求成功");
}
// 请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    
    NSLog(@"请求失败");
    
}

#pragma mark 监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    
    for (SKPaymentTransaction *transaction in transactions) {
         // 如果小票状态是购买完成
        if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            //更新界面或数据,把用户购买得商品交给用户
            // 返回购买的商品信息
            [self verifyPruchase];
            
            // 商品购买成功,可调用本地接口
        }else if (SKPaymentTransactionStateRestored == transaction.transactionState){
            // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            
        }else if(SKPaymentTransactionStateFailed == transaction.transactionState){
            //支付失败
            // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            
            
            
        }
    }
    
    
    
}

//交易结束
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"交易结束");
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)verifyPruchase{
    
    // 验证凭证,获取到苹果返回的交易凭证
    // appstoreReceiptURL ios 7.0增加的,购买交易完成后,会将凭证存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    // 发送网络POST请求,对购买凭证进行验证
    //测试验证地址:https://sandbox.itunes.apple.com/verifyReceipt
    //正式验证地址:https://buy.itunes.apple.com/verifyReceipt
    NSURL *url = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
    urlRequest.HTTPMethod = @"POST";
    NSString *encodeStr =[receiptData base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    urlRequest.HTTPBody = payloadData;
    // 提交验证请求,并获得官方的验证JSON结果,iOS9 更新了另一个方法
    
    NSData *result = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
    // 官方验证结果为空
    if (result == nil) {
        NSLog(@"验证失败");
        return;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingAllowFragments error:nil];
    if (dict != nil) {
        // 比对字典中以下信息基本上可以保证数据安全
        // bundle_id , application_version , product_id , transaction_id
        NSLog(@"验证成功！购买的商品是：%@", @"_productName");
    }
    
    
    
    
    
    
    
    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
