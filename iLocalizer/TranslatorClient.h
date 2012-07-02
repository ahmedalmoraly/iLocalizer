//
//  TranslatorClient.h
//  Localizer
//
//  Created by Ahmad al-Moraly on 6/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AFHTTPClient.h"

typedef enum {
    TranslatorLanguage_en,
    TranslatorLanguage_es,
    TranslatorLanguage_ar,
}TranslatorLanguage;

@interface TranslatorClient : AFHTTPClient

+(TranslatorClient *)sharedClient;

-(NSString *)translateText:(NSString *)text from:(TranslatorLanguage)from to:(TranslatorLanguage)to;

@end
