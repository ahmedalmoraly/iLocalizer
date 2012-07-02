//
//  Helper.m
//  Localizer
//
//  Created by Ahmad al-Moraly on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Helper.h"

@interface Helper ()

+(void)localizeFile:(NSString *)filePath;

+(void)localizeNibFile:(NSString *)nibName withSourcePath:(NSString *)sourcePath andDestinationPath:(NSString *)destinationPath;

+(void)localizeCodeFile:(NSString *)filePath;

+(BOOL)shouldLocalizeString:(NSString *)string inLine:(NSString *)line;

    //+(void)translateStringsFile:(NSString *)filePath;

@end

@implementation Helper

static NSString *originFolderPath;
static NSString *destinationFolderPath;
static NSString *baseFolderPath;

+(void)translate {

//    [self translateStringsFile:@"/Users/ahmadal-moraly/Developer/TeacherPal copy 2/TeacherPalRemakeUI/TeacherPal/es.lproj/Localizable.strings"];   
    
}

+(void)localizeFilesInPath:(NSString *)path 
{
    baseFolderPath = [path copy];
    
    NSError *error;
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    for (NSString *filePath in array) {
        // create the path
        NSString *wholePath = [path stringByAppendingPathComponent:filePath];
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:wholePath isDirectory:&isDirectory];
        
        
        if (isDirectory) {
            // loop again
            if ([wholePath.lastPathComponent isEqualToString:@"en.lproj"]) {
                originFolderPath = [wholePath copy];
                continue;
            } else if ([wholePath.lastPathComponent isEqualToString:@"ar.lproj"]) {
                destinationFolderPath = [wholePath copy];
            }
            [self localizeFilesInPath:wholePath];
        }
        else {
            [self localizeFile:wholePath];
        }
    }
}

+(void)localizeNibFile:(NSString *)nibName withSourcePath:(NSString *)sourcePath andDestinationPath:(NSString *)destinationPath
{
    NSString *localizedStringFile = [destinationPath stringByAppendingPathComponent:[[nibName stringByDeletingPathExtension] stringByAppendingPathExtension:@"strings"]];
    
        // check for empty string file
    NSError *error;
    NSString *strings = [NSString stringWithContentsOfFile:localizedStringFile encoding:NSUTF16StringEncoding error:&error];
    if (!strings || [strings isEqualToString:@"\"/* comment */\""]) {
        strings = @"/* comment */";
        [strings writeToFile:localizedStringFile atomically:YES encoding:NSUTF16StringEncoding error:&error];
    }
    else {
            // translate Strings File
            //[self translateStringsFile:localizedStringFile];

        NSString *sourceNib = [sourcePath stringByAppendingPathComponent:nibName];
        NSString *destNib = [destinationPath stringByAppendingPathComponent:nibName];

        NSString *command = [NSString stringWithFormat:@"ibtool  --previous-file %@ --incremental-file %@ --strings-file %@ --localize-incremental --write %@ %@", sourceNib, destNib, localizedStringFile, destNib, sourceNib];

        command = [NSString stringWithFormat:@"ibtool --strings-file %@ --write %@ %@", localizedStringFile, destNib, sourceNib];

        int result = system(command.UTF8String);

        if (result) {
            NSLog(@"Error Localize Nib: %@", destNib);
        }
    }
}

+(void)localizeCodeFile:(NSString *)filePath {
    NSLog(@"\n\nLocalizing File: %@\n", filePath);
    
    // get file content
    NSError *readingError;
    NSString *fileData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&readingError];
    
    //NSLog(@"File: %@ \n\n %@\n\n\n", [NSString stringWithFormat:@"%@/%@", path, file], fileData);
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileData componentsSeparatedByString:@"\n"]];
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (NSString *line in lines) {
        
        
        NSString * stringToLocalize;
        NSString *modifiedLine = [line copy];
        
        NSScanner *scanner = [NSScanner scannerWithString:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        while (!scanner.isAtEnd) {
            // Check for escaped characters
            [scanner scanUpToString:@"@\"" intoString:nil];
            
            if (scanner.isAtEnd) {
                [result addObject:modifiedLine];
                break;
            }
            
            // check if the scanner didn't move
            if (scanner.scanLocation == 0) {
                NSLog(@"");
            }
            
            scanner.scanLocation += 2;
            [scanner scanUpToString:@"\"" intoString:&stringToLocalize];
            
            if (![self shouldLocalizeString:stringToLocalize inLine:line]) {
                continue;
            }
            
            char ok[1] = {0};
            printf("\nLocalize string:  %s \nin Line: %s ??: ", [stringToLocalize cStringUsingEncoding:NSUTF8StringEncoding], [line cStringUsingEncoding:NSUTF8StringEncoding]);
            
            scanf("%s", ok);
            
            if (ok[0] == '0') {
                continue;
            }
            else {
                
                modifiedLine = [modifiedLine stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"@\"%@\"", stringToLocalize] withString:[NSString stringWithFormat:@"NSLocalizedString(@\"%@\", nil)", stringToLocalize]];
                
                if (scanner.isAtEnd) {
                    [result addObject:modifiedLine];                            
                }
                
                //NSLog(@"%@", modifiedLine);
            }
            
            
        }
        
    }
    
    NSString *modifiedFile = [result componentsJoinedByString:@"\n"];
    NSError *writingError;
    [modifiedFile writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&writingError];
}

+(void)localizeFile:(NSString *)filePath
{
    if ([filePath.lastPathComponent.pathExtension isEqualToString:@"m"]) {
        //[self localizeCodeFile:filePath];
    } else if ([filePath.lastPathComponent.pathExtension isEqualToString:@"xib"]) {
        [self localizeNibFile:filePath.lastPathComponent withSourcePath:originFolderPath andDestinationPath:destinationFolderPath];
    } else if ([filePath.lastPathComponent.pathExtension isEqualToString:@"strings"]) {
            //[self translateStringsFile:filePath];
    }
    
}

+(BOOL)shouldLocalizeString:(NSString *)string inLine:(NSString *)line {
    
    NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // check if it's already localized
    if ([line rangeOfString:@"NSLocalizedString("].location != NSNotFound) {
        NSLog(@"already localized !!");
        return NO;
    }
    
    // check if comment
    if ([trimmedLine hasPrefix:@"//"]) {
        NSLog(@"commented");
        return NO;
    }
    
    // check if empty or null
    if (!string || !string.length || !trimmedString || !trimmedString.length) {
        NSLog(@"empty or nil");
        return NO;
    }
    
    // check for NSLog
    if ([trimmedLine hasPrefix:@"NSLog"]) {
        NSLog(@"Logger");
        return NO;
    }
    
    // check for Notification
    if ([trimmedLine rangeOfString:@"NSNotificationCenter"].location != NSNotFound) {
        NSLog(@"Notification");
        return NO;
    }
    
    // check for animationWithKeyPath
    if ([trimmedLine rangeOfString:@"animationWithKeyPath"].location != NSNotFound) {
        NSLog(@"Animation");
        return NO;
    }
    
    // check for nib names
    if ([trimmedLine rangeOfString:@"NibName"].location != NSNotFound) {
        NSLog(@"Nib Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedLine rangeOfString:@"fetchObjectsForEntityName"].location != NSNotFound) {
        NSLog(@"Entity Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedLine rangeOfString:@"entityForName"].location != NSNotFound) {
        NSLog(@"Entity Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedLine rangeOfString:@"fetchRequestWithEntityName"].location != NSNotFound) {
        NSLog(@"Entity Name");
        return NO;
    }
    
    // check for descriptors 
    if ([trimmedLine rangeOfString:@"sortDescriptorWithKey"].location != NSNotFound) {
        NSLog(@"Descriptor Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedLine rangeOfString:@"insertNewObjectForEntityForName"].location != NSNotFound) {
        NSLog(@"Entity Name");
        return NO;
    }
    
    // check for paths 
    if ([trimmedLine rangeOfString:@"stringByAppendingPathComponent"].location != NSNotFound) {
        NSLog(@"Entity Name");
        return NO;
    }
    
    // check for font names 
    if ([trimmedLine rangeOfString:@"fontWithName"].location != NSNotFound) {
        NSLog(@"Font Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedLine rangeOfString:@"predicateWithFormat"].location != NSNotFound) {
        NSLog(@"Predicate");
        return NO;
    }
    
    if (![trimmedString stringByReplacingOccurrencesOfString:@"%@" withString:@""].length || ![string stringByReplacingOccurrencesOfString:@"%i" withString:@""].length) {
        NSLog(@"format");
        return NO;
    }
    
    if ([trimmedString isEqualToString:@","] || [trimmedString isEqualToString:@";"] || [trimmedString isEqualToString:@"."] || [trimmedString isEqualToString:@"}"] || [trimmedString isEqualToString:@"{"] || [trimmedString isEqualToString:@")"] || [trimmedString isEqualToString:@"("] || [trimmedString isEqualToString:@"-"] || [trimmedString isEqualToString:@"_"] || [trimmedString isEqualToString:@"/"] || [trimmedString isEqualToString:@"!"] || [trimmedString isEqualToString:@"%"]) 
    {
        NSLog(@"special characters");
        return NO;
    }
    
    if ([trimmedString.pathExtension isEqualToString:@"png"] || [trimmedString.pathExtension isEqualToString:@"zip"]) {
        NSLog(@"path extentions");
        return NO;
    }
    
    
    return YES;
}

//
//+(void)translateStringsFile:(NSString *)filePath {
//        // read data form file
//
//    NSStringEncoding encoding;
//    NSString *fileData = [NSString stringWithContentsOfFile:filePath usedEncoding:&encoding error:nil];
//    
//    NSArray *array = [fileData componentsSeparatedByString:@"\n\n"];
//    NSMutableArray *translatedArray = [[NSMutableArray alloc] init];
//    if (array.count < 2) {
//        NSLog(@"Empty localized String");
//        return;
//    }
//    [array enumerateObjectsUsingBlock:^(NSString *string, NSUInteger idx, BOOL *stop) {
//        if (!string.length) {
//            return;
//        }
//        NSMutableArray *splitedStrings = [[string componentsSeparatedByString:@"\n"] mutableCopy];
//        
//        if (idx == 0) {
//            [translatedArray addObject:[splitedStrings objectAtIndex:0]];
//            [splitedStrings removeObjectAtIndex:0]; 
//        }
//        else if (idx == array.count - 1) {
//            [splitedStrings removeLastObject];
//        }
//        
//        NSString *obj = splitedStrings.lastObject;
//        
//        [translatedArray addObject:[splitedStrings objectAtIndex:0]];
//        [translatedArray addObject:@"\n"];
//        
//        NSArray *keyAndValue = [obj componentsSeparatedByString:@"= \""];
//        NSString *textToTranslate = [keyAndValue.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";"]];
//
//        NSString *translatedText;
//        if (textToTranslate.length) {
//            translatedText = [[TranslatorClient sharedClient] translateText:textToTranslate from:TranslatorLanguage_en to:TranslatorLanguage_es];
//        }
//        if (translatedText) {
//            NSString *data = [[keyAndValue objectAtIndex:0] stringByAppendingFormat:@" = \"%@;", translatedText];
//            [translatedArray addObject:data];
//        } else {
//            [translatedArray addObject:obj];
//        }
//        if (idx == array.count - 1) {
//            [translatedArray addObject:@"\n"];
//        } else {
//            [translatedArray addObject:@"\n\n"];
//        }
//
//    }];
//
//    NSString *finalString = [translatedArray componentsJoinedByString:@""];
//
//    [finalString writeToFile:filePath atomically:YES encoding:NSUTF16StringEncoding error:nil];
//    
//}

@end
