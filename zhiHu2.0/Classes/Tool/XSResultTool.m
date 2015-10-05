//
//  XSResultTool.m
//  zhiHu2.0
//
//  Created by xiaos on 15/9/23.
//  Copyright (c) 2015年 com.xsdota. All rights reserved.
//

#import "XSResultTool.h"

#import "XSHttpTool.h"
#import "MJExtension.h"

#import "XSCssFile.h"

#import "XSContentResult.h"

/** 获取最新消息 */
#define NEW_URL @"http://news-at.zhihu.com/api/4/news/latest"

#define OLD_URL @"http://news.at.zhihu.com/api/4/news/before/"

#define CONTENT_URL @"http://news-at.zhihu.com/api/4/news/"


@implementation XSResultTool

/** 请求最新故事 */
+ (void)getNewDictForSuccess:(void (^)(XSResult *))success failure:(void (^)(NSError *))failure
{
    [XSHttpTool GET:NEW_URL parameters:nil success:^(id responseObject) {
        //请求成功传两个数组到外层代码中
        
        //字典转模型
        XSResult *result = [XSResult objectWithKeyValues:responseObject];
        
        if (success) {
            success(result);
        }
        
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}
/** 请求以前的故事 */
- (void)getOldDictForSuccess:(void (^)(XSResult *))success failure:(void (^)(NSError *))failure
{
    NSString *oldURL = [OLD_URL stringByAppendingString:_dateStr];
    
    [XSHttpTool GET:oldURL parameters:nil success:^(id responseObject) {
        XSResult *result = [XSResult objectWithKeyValues:responseObject];
        if (success) {
            success(result);
        }
        
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}
/** 请求故事内容 */
- (void)getStoriesContentWithSuccess:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    NSString *contentURL = [CONTENT_URL stringByAppendingString:_stoiresId];
    
    [XSHttpTool GET:contentURL parameters:nil success:^(id responseObject) {
        
        //字典转模型
        XSContentResult *result = [XSContentResult objectWithKeyValues:responseObject];
        //内容标题
        NSString *titleStr = result.title;
        //内容正文
        NSString *bodyStr = result.body;
        //获取css文件的url
        NSString *cssUrl = [result.css lastObject];
        
        //若旧的url为空 或者旧的url与新的url不一样 就从网络上下载 更新css文件
        if (![cssUrl isEqualToString:[XSCssFile getoOldCssUrl]] || ![XSCssFile getoOldCssUrl]) {
            XSLog(@"更新css文件");
            [XSCssFile saveCssFileWithUrl:cssUrl];
        }
        
        //若css文件url一致 直接从本地读取
        NSString *htmlHead = @"<html><head><title></title><link type=\"text/css\" rel=\"stylesheet\" href = \"news.css\" /></head><body>";
        NSString *replaceStr = [NSString stringWithFormat:@"<div class=\"headline-title\"><h1>%@</h1></div>",titleStr];
        NSRange range = [bodyStr rangeOfString:@"<div class=\"img-place-holder\"></div>"];
        
#warning mark - 防止以后知乎这里变动
        if (range.length != 0) {
            bodyStr = [bodyStr stringByReplacingCharactersInRange:range withString:replaceStr];
        }else{
            XSLog(@"内容的html页面有变动");
        }
        
        NSString *htmlFoot = @"</body></html>";
        NSString *htmlStr = [NSString stringWithFormat:@"%@%@%@",htmlHead,bodyStr,htmlFoot];
        
        //将处理好的htmlStr传出
        if (success) {
            success(htmlStr);
        }
        
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

}
@end
