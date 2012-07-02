//
//  TranslatorClient.m
//  Localizer
//
//  Created by Ahmad al-Moraly on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TranslatorClient.h"
#import "AFNetworking.h"

@interface AuthenticationClient : AFHTTPClient

+(NSString *)accessToken;

@end

@implementation AuthenticationClient

+(AuthenticationClient *)sharedClient {
    static AuthenticationClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"]];
    });
    return sharedClient;
}

+(NSString *)accessToken {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"client_credentials" forKey:@"grant_type"];
    [parameters setObject:@"http://api.microsofttranslator.com" forKey:@"scope"];
    [parameters setObject:@"TeacherPalClientID" forKey:@"client_id"];
    [parameters setObject:@"TeacherPalClientSecret" forKey:@"client_secret"];
    
 
     NSURLRequest *request = [[self sharedClient] requestWithMethod:@"POST" path:@"" parameters:parameters];
     AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"respone: %@", JSON);
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@", error);
        
    }];
     
     [operation start];
     
     while (!operation.isFinished) {
             // dummy loop
     }
    
        //NSLog(@"operation.response %@", operation.responseJSON);
     NSString *accessToken = [NSString stringWithFormat:@"Bearer %@", [operation.responseJSON objectForKey:@"access_token"]];
        //NSLog(@"AccessToken: %@", accessToken);
     
    return accessToken;
}


@end

@interface TranslatorClient ()

-(NSString *)extractTranslationFromResponse:(NSString *)response;

@end

@implementation TranslatorClient

static inline NSString *localeIdentifierForLanguage(TranslatorLanguage lang) {
    if(lang == TranslatorLanguage_en) {return @"en";} 
    else if(lang == TranslatorLanguage_es) {return @"es";} 
    else if(lang == TranslatorLanguage_ar) { return @"ar";}
    else {return @"";}
}


+(TranslatorClient *)sharedClient {
    static TranslatorClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.microsofttranslator.com/V2/Http.svc/Translate"]];
    });
    return sharedClient;
}

-(NSString *)translateText:(NSString *)text from:(TranslatorLanguage)from to:(TranslatorLanguage)to {
    
    NSString *fromLang = localeIdentifierForLanguage(from);
    
    NSString *toLang = localeIdentifierForLanguage(to);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        //[parameters setObject:@"" forKey:@"appId"];
    [parameters setObject:text forKey:@"text"];
    [parameters setObject:fromLang forKey:@"from"];
    [parameters setObject:toLang forKey:@"to"];
    [parameters setObject:@"text/plain" forKey:@"contentType"];
    
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:@"" parameters:parameters];
    
    [request addValue:[AuthenticationClient accessToken] forHTTPHeaderField:@"Authorization"];

	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"respone: %@", JSON);
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@", error);
        
    }];
        //NSLog(@"request Parameters: %@", parameters);
    [operation start];
    
    while (!operation.isFinished) {
            // dummy loop
    }
    
    NSLog(@"operation.response %@", operation.responseString);
    NSString *translation = [self extractTranslationFromResponse:operation.responseString];
    return translation;
}

-(id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    
    if (self) {
        
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        
            // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
        [self setDefaultHeader:@"Accept" value:@"application/json"];
    }
    
    return self;
}

-(NSString *)extractTranslationFromResponse:(NSString *)response {
    NSString *translation;
    
    NSScanner *scanner = [NSScanner scannerWithString:response];
    [scanner scanUpToString:@"/\">" intoString:nil];
    if (scanner.isAtEnd) {
        return nil;
    }
    scanner.scanLocation += 3;
    [scanner scanUpToString:@"<" intoString:&translation];
    
    return translation;
}


@end
