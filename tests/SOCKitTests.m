//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <SenTestingKit/SenTestingKit.h>
#import <QuartzCore/QuartzCore.h>

#import "SOCKit.h"

typedef void (^SimpleBlock)(void);

@interface SOCTestObject : NSObject

- (id)initWithId:(NSInteger)ident floatValue:(CGFloat)flv doubleValue:(double)dv longLongValue:(long long)llv stringValue:(NSString *)string;
- (id)initWithId:(NSInteger)ident floatValue:(CGFloat)flv doubleValue:(double)dv longLongValue:(long long)llv stringValue:(NSString *)string userInfo:(id)userInfo;

@property (nonatomic, readwrite, assign) NSInteger ident;
@property (nonatomic, readwrite, assign) CGFloat flv;
@property (nonatomic, readwrite, assign) double dv;
@property (nonatomic, readwrite, assign) long long llv;
@property (nonatomic, readwrite, copy) NSString* string;
@end

@implementation SOCTestObject

@synthesize ident;
@synthesize flv;
@synthesize dv;
@synthesize llv;
@synthesize string;

- (void)dealloc {
  [string release]; string = nil;
  [super dealloc];
}

- (id)initWithId:(NSInteger)anIdent floatValue:(CGFloat)anFlv doubleValue:(double)aDv longLongValue:(long long)anLlv stringValue:(NSString *)aString {
  if ((self = [super init])) {
    self.ident = anIdent;
    self.flv = anFlv;
    self.dv = aDv;
    self.llv = anLlv;
    self.string = aString;
  }
  return self;
}

- (id)initWithId:(NSInteger)anIdent floatValue:(CGFloat)anFlv doubleValue:(double)aDv longLongValue:(long long)anLlv stringValue:(NSString *)aString userInfo:(id)userInfo {
  return [self initWithId:anIdent floatValue:anFlv doubleValue:aDv longLongValue:anLlv stringValue:aString];
}

@end

@interface SOCKitTests : SenTestCase
@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SOCKitTests


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testEmptyCases {
  STAssertTrue([SOCStringFromStringWithObject(nil, nil) isEqualToString:@""], @"Should be the same string.");

  STAssertTrue([SOCStringFromStringWithObject(@"", nil) isEqualToString:@""], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@" ", nil) isEqualToString:@" "], @"Should be the same string.");

  STAssertTrue([SOCStringFromStringWithObject(@"abcdef", nil) isEqualToString:@"abcdef"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"abcdef", [NSArray array]) isEqualToString:@"abcdef"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testFailureCases {
  STAssertThrows([SOCPattern patternWithString:@"()"], @"Empty parameters are not allowed.");
  STAssertThrows([SOCPattern patternWithString:@"(dilly)()"], @"Empty parameters are not allowed.");

  STAssertThrows([SOCPattern patternWithString:@")"], @"Dangling parenthesis.");
  STAssertThrows([SOCPattern patternWithString:@"(dilly))"], @"Dangling parenthesis.");
  STAssertThrows([SOCPattern patternWithString:@"(dilly)/)"], @"Dangling parenthesis.");

  STAssertThrows([SOCPattern patternWithString:@"("], @"No closing parenthesis.");
  STAssertThrows([SOCPattern patternWithString:@"(dilly)("], @"No closing parenthesis.");
  STAssertThrows([SOCPattern patternWithString:@"(dilly)/("], @"No closing parenthesis.");

  STAssertThrows([SOCPattern patternWithString:@"(())"], @"Nested parameters are not allowed.");
  STAssertThrows([SOCPattern patternWithString:@"((dilly))"], @"Nested parameters are not allowed.");
  STAssertThrows([SOCPattern patternWithString:@"(dilly(dilly)dilly)"], @"Nested parameters are not allowed.");

  STAssertThrows([SOCPattern patternWithString:@"(initWithId:)(cat:)"], @"Outbound parameters must be separated by strings.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testSingleParameterCoding {
  NSDictionary* obj = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:1337], @"leet",
                       [NSNumber numberWithInt:5000], @"five",
                       nil];
  STAssertTrue([SOCStringFromStringWithObject(@"(leet)", obj) isEqualToString:@"1337"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"(five)", obj) isEqualToString:@"5000"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"(six)", obj) isEqualToString:@"(null)"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testMultiParameterCoding {
  NSDictionary* obj = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:1337], @"leet",
                       [NSNumber numberWithInt:5000], @"five",
                       nil];
  STAssertTrue([SOCStringFromStringWithObject(@"(leet)(five)", obj) isEqualToString:@"13375000"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"(five)(five)", obj) isEqualToString:@"50005000"], @"Should be the same string.");
  STAssertTrue([SOCStringFromStringWithObject(@"(five)/(five)/(five)/(five)/(five)/(five)", obj) isEqualToString:@"5000/5000/5000/5000/5000/5000"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testCollectionOperators {
  NSDictionary* obj = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:1337], @"leet",
                       [NSNumber numberWithInt:5000], @"five",
                       nil];
  STAssertTrue([SOCStringFromStringWithObject(@"(@count)", obj) isEqualToString:@"2"], @"Should be the same string.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testOutboundParameters {
  SOCPattern* pattern = [SOCPattern patternWithString:@"soc://(initWithId:)"];
  STAssertTrue([pattern doesStringConform:@"soc://3"], @"String should conform.");
  STAssertTrue([pattern doesStringConform:@"soc://33413413454353254235245235"], @"String should conform.");

  STAssertFalse([pattern doesStringConform:@""], @"String should not conform.");
  STAssertFalse([pattern doesStringConform:@"soc://"], @"String should not conform.");

  STAssertTrue([pattern doesStringConform:@"soc://joe"], @"String might conform.");

  pattern = [SOCPattern patternWithString:@"soc://(initWithId:)/sandwich"];
  STAssertTrue([pattern doesStringConform:@"soc://3/sandwich"], @"String should conform.");
  STAssertTrue([pattern doesStringConform:@"soc://33413413454353254235245235/sandwich"], @"String should conform.");

  STAssertFalse([pattern doesStringConform:@""], @"String should not conform.");
  STAssertFalse([pattern doesStringConform:@"soc://"], @"String should not conform.");
  STAssertFalse([pattern doesStringConform:@"soc:///sandwich"], @"String should not conform.");

  pattern = [SOCPattern patternWithString:@"soc://(initWithId:)/sandwich/(cat:)"];
  STAssertTrue([pattern doesStringConform:@"soc://3/sandwich/dilly"], @"String should conform.");
  STAssertTrue([pattern doesStringConform:@"soc://33413413454353254235245235/sandwich/dilly"], @"String should conform.");

  STAssertFalse([pattern doesStringConform:@""], @"String should not conform.");
  STAssertFalse([pattern doesStringConform:@"soc://"], @"String should not conform.");
  STAssertFalse([pattern doesStringConform:@"soc://33413413454353254235245235/sandwich/"], @"String should not conform.");
  STAssertFalse([pattern doesStringConform:@"soc:///sandwich/"], @"String should not conform.");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)testPerformSelectorOnObjectWithSourceString {
  SOCPattern* pattern = [SOCPattern patternWithString:@"soc://(initWithId:)/(floatValue:)/(doubleValue:)/(longLongValue:)/(stringValue:)"];
  SOCTestObject* testObject = [pattern performPatternSelectorOnObject:[SOCTestObject class] sourceString:@"soc://3/3.5/6.14/13413143124321/dilly"];
  STAssertEquals(testObject.ident, (NSInteger)3, @"Values should be equal.");
  STAssertEquals(testObject.flv, (CGFloat)3.5, @"Values should be equal.");
  STAssertEquals(testObject.dv, 6.14, @"Values should be equal.");
  STAssertEquals(testObject.llv, (long long)13413143124321, @"Values should be equal.");
  STAssertTrue([testObject.string isEqualToString:@"dilly"], @"Values should be equal.");

  testObject = [pattern performSelector:@selector(initWithId:floatValue:doubleValue:longLongValue:stringValue:userInfo:) onObject:[SOCTestObject class] sourceString:@"soc://3/3.5/6.14/13413143124321/dilly"];
  STAssertEquals(testObject.ident, (NSInteger)3, @"Values should be equal.");
  STAssertEquals(testObject.flv, (CGFloat)3.5, @"Values should be equal.");
  STAssertEquals(testObject.dv, 6.14, @"Values should be equal.");
  STAssertEquals(testObject.llv, (long long)13413143124321, @"Values should be equal.");
  STAssertTrue([testObject.string isEqualToString:@"dilly"], @"Values should be equal.");

  pattern = [SOCPattern patternWithString:@"soc://(id)/(flv)/(dv)/(llv)/(string)"];
  testObject = [pattern performSelector:@selector(initWithId:floatValue:doubleValue:longLongValue:stringValue:) onObject:[SOCTestObject class] sourceString:@"soc://3/3.5/6.14/13413143124321/dilly"];
  STAssertEquals(testObject.ident, (NSInteger)3, @"Values should be equal.");
  STAssertEquals(testObject.flv, (CGFloat)3.5, @"Values should be equal.");
  STAssertEquals(testObject.dv, 6.14, @"Values should be equal.");
  STAssertEquals(testObject.llv, (long long)13413143124321, @"Values should be equal.");
  STAssertTrue([testObject.string isEqualToString:@"dilly"], @"Values should be equal.");

  pattern = [SOCPattern patternWithString:@"soc://(setIdent:)"];
  [pattern performPatternSelectorOnObject:testObject sourceString:@"soc://6"];
  STAssertEquals(testObject.ident, (NSInteger)6, @"Values should be equal.");

  pattern = [SOCPattern patternWithString:@"soc://(setIdent:)"];
  [pattern performSelector:@selector(setLlv:) onObject:testObject sourceString:@"soc://6"];
  STAssertEquals(testObject.llv, (long long)6, @"Values should be equal.");
}

@end
