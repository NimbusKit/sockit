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

#import "SOCKit.h"

typedef void (^SimpleBlock)(void);

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
}

@end
