//
//  AQCocoaXMLParser.m
//  XMLPerformance
//
//  Created by Miklós Fazekas on 5/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AQCocoaXMLParser.h"

#import "AQXMLParser.h"

@implementation AQCocoaXMLParser

+ (NSString *)parserName {
    return @"AQXMLParser";
}

+ (XMLParserType)parserType {
    return XMLParserTypeAQXMLParser;
}

- (Class)xmlParserClass
{
   return [AQXMLParser class]; 
}

@end
