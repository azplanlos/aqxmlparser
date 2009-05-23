//
//  AQXMLParserTestCase.m
//  UnitTests
//
//  Created by Miklós Fazekas on 5/12/09.
//  Copyright 2009 www.unittested.com/blog . All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "AQXMLParser.h"

@interface MyParserDelegate : NSObject<AQXMLParserDelegate>
{
    NSMutableArray* invokedMethods;
}

- (NSArray*)invokedMethods;

@end

@implementation MyParserDelegate

- (id) init
{
    self = [super init];
    if (self != nil) {
        invokedMethods = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void) dealloc
{
    [invokedMethods dealloc];
    [super dealloc];
}

- (NSArray*)invokedMethods
{
    return [[invokedMethods copy] autorelease];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    return YES;
}

- (void)forwardInvocation:(NSInvocation *)inv
{
    [inv retainArguments];
    [invokedMethods addObject:inv];
}

@end



@interface AQXMLParserTestCase : SenTestCase
{
    
}
@end


@implementation AQXMLParserTestCase


- (void)_compareAQWithNSWithXML:(NSString*)xml
{
    for (int variation = 0; variation < 8;++variation)
    {
        BOOL shouldProcessNamespace = variation % 2;
        BOOL shouldReportNamespacePrefixes =  (variation / 2) % 2;
        BOOL shouldResolveExternalEntities = (variation / 4) % 2;
        
        NSData* data = [xml dataUsingEncoding:NSUTF8StringEncoding];
        NSArray* aqmethods = 0;
        {
            AQXMLParser* parser = [[[AQXMLParser alloc] initWithData:data] autorelease];
            [parser setShouldProcessNamespaces:shouldProcessNamespace];
            [parser setShouldReportNamespacePrefixes:shouldReportNamespacePrefixes];
            [parser setShouldResolveExternalEntities:shouldResolveExternalEntities];
            MyParserDelegate* delegate1 = [[[MyParserDelegate alloc] init] autorelease];
            parser.delegate = delegate1;
            [parser parse];
            aqmethods = [delegate1 invokedMethods];
        }
        NSArray* nsmethods = 0;
        {
            NSXMLParser* parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
            [parser setShouldProcessNamespaces:shouldProcessNamespace];
            [parser setShouldReportNamespacePrefixes:shouldReportNamespacePrefixes];
            [parser setShouldResolveExternalEntities:shouldResolveExternalEntities];
            MyParserDelegate* delegate2 = [[[MyParserDelegate alloc] init] autorelease];
            parser.delegate = delegate2;
            [parser parse];
            nsmethods = [delegate2 invokedMethods];
        }
        
        STAssertEquals([aqmethods count],[nsmethods count],@" - number of messages received by delegates are different");
        for (int i = 0; i < [aqmethods count]; ++i) {
            NSInvocation* nsinvocation = [nsmethods objectAtIndex:i];
            NSInvocation* aqinvocation = [aqmethods objectAtIndex:i];
            
            NSString* nsselector = NSStringFromSelector([nsinvocation selector]);
            NSString* aqselector = NSStringFromSelector([aqinvocation selector]);
            STAssertEqualObjects(aqselector,nsselector,@" - selector %d does not equal",i);
            if ([[nsinvocation methodSignature] numberOfArguments] > 3) {
                
                for (int i = 3; i < [[nsinvocation methodSignature] numberOfArguments]; ++i) {
                    NSString* paramName = [[nsselector componentsSeparatedByString:@":"] objectAtIndex:i-2];
                    NSString* nsparam = 0;
                    NSString* aqparam = 0;
                    [nsinvocation getArgument:&nsparam atIndex:i];
                    [aqinvocation getArgument:&aqparam atIndex:i];
                    
                    if ([aqparam isKindOfClass:[NSError class]] && [nsparam isKindOfClass:[NSError class]]) {
                        // Todo: check why NSError isEqual return NO.  For now we just compare by their description.
                        STAssertEqualObjects([aqparam description],[nsparam description],@"- parameter '%@' (%d th parameter in call to selector %@)",paramName,i-1,nsselector);
                    } else {
                        STAssertEqualObjects(aqparam,nsparam,@"- parameter '%@' (%d th parameter in call to selector %@)",paramName,i-1,nsselector);
                    }
                }
            }
        }
    }
}

- (void)testSmoke
{
    NSString* xml = @"<test></test>";
    [self _compareAQWithNSWithXML:xml];
}

- (void)testXMLWithAttributes
{
    NSString* xml = @"<test><data foo='as'></data></test>";
    [self _compareAQWithNSWithXML:xml];
}

- (void)testXMLWithNamespace
{
    NSString* xml = @"<x xmlns:edi='http://unittested.com/blog'> <edi:foo></edi:foo></x>"; //
    [self _compareAQWithNSWithXML:xml];
}

- (void)testXMLWithTwoNamespace
{
    NSString* xml = @"<?xml version=\"1.0\"?> \
                      <!-- both namespace prefixes are available throughout --> \
                      <bk:book xmlns:bk='urn:loc.gov:books' \
                          xmlns:isbn='urn:ISBN:0-395-36341-6'> \
                      <bk:title>Cheaper by the Dozen</bk:title> \
                      <isbn:number>1568491379</isbn:number> \
                      </bk:book>"; 
    [self _compareAQWithNSWithXML:xml];
}

- (void)testXMLWithNamespaceScooping
{
    NSString* xml = @"<?xml version=\"1.0\"?> \
                      <!-- initially, the default namespace is \"books\" --> \
                      <book xmlns='urn:loc.gov:books' \
                        xmlns:isbn='urn:ISBN:0-395-36341-6'> \
                      <title>Cheaper by the Dozen</title> \
                      <isbn:number>1568491379</isbn:number> \
                      <notes> \
                        <!-- make HTML the default namespace for some commentary --> \
                        <p xmlns='http://www.w3.org/1999/xhtml'> \
                            This is a <i>funny</i> book! \
                        </p> \
                      </notes> \
                      </book>";
    [self _compareAQWithNSWithXML:xml];
}

- (void)testXMLWithComment
{
    
}

- (void)testXMLWithExternalDTD
{
    NSString* xml = @"<?xml version=\"1.0\" standalone=\"no\" ?> \
                     <!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \
                      \"http://www.w3.org/TR/REC-html40/loose.dtd\"> \
                     <HTML> \
                     <HEAD> \
                        <TITLE>A typical HTML file</TITLE> \
                     </HEAD> \
                     <BODY> \
                          This is the typical structure of an HTML file. It follows \
                          the notation of the HTML 4.0 specification, including tags \
                          that have been deprecated (hence the \"transitional\" label). \
                    </BODY> \
                    </HTML>";
    [self _compareAQWithNSWithXML:xml];
}

- (void)testXMLWithInternalDTD
{
    NSString* xml = @"<?xml version=\"1.0\"?> \
                      <!DOCTYPE note [ \
                      <!ELEMENT note (to,from,heading,body)> \
                      <!ELEMENT to (#PCDATA)> \
                      <!ELEMENT from (#PCDATA)> \
                      <!ELEMENT heading (#PCDATA)> \
                      <!ELEMENT body (#PCDATA)> \
                      ]> \
                    <note> \
                    <to>Tove</to> \
                    <from>Jani</from> \
                    <heading>Reminder</heading> \
                    <body>Don't forget me this weekend</body> \
                    </note>";
   [self _compareAQWithNSWithXML:xml]; 
}

- (void)testXMLWithMissingEndTagError
{
    NSString* xml = @"<?xml version=\"1.0\"?> \
                    @<foo><bar></foo>";
    [self _compareAQWithNSWithXML:xml]; 
}

- (void)testXMLWithMissingEndError
{
    NSString* xml = @"<?xml version=\"1.0\"?> \
                    @<foo><bar";
    [self _compareAQWithNSWithXML:xml]; 
} 

@end
