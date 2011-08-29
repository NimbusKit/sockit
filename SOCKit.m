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

#import "SOCKit.h"

#import <assert.h>

typedef enum {
  SOCArgumentTypeNone,
  SOCArgumentTypePointer,
  SOCArgumentTypeBool,
  SOCArgumentTypeInteger,
  SOCArgumentTypeLongLong,
  SOCArgumentTypeFloat,
  SOCArgumentTypeDouble,
} SOCArgumentType;

SOCArgumentType SOCArgumentTypeForTypeAsChar(char argType);


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface SOCParameter : NSObject {
@private
  NSString* _string;
  BOOL _isOutbound;
}

- (id)initWithString:(NSString *)string;
+ (id)parameterWithString:(NSString *)string;

- (NSString *)string;

- (BOOL)isOutbound; // E.g. @"initWithValue:"
- (BOOL)isInbound;  // E.g. @"value"

// Private
- (void)_compileParameter;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface SOCPattern()

- (void)_compilePattern;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SOCPattern


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [_patternString release]; _patternString = nil;
  [_tokens release]; _tokens = nil;
  [_inboundParameters release]; _inboundParameters = nil;
  [_outboundParameters release]; _outboundParameters = nil;
  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithString:(NSString *)string {
  if ((self = [super init])) {
    _patternString = [string copy];

    [self _compilePattern];
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)patternWithString:(NSString *)string {
  return [[[self alloc] initWithString:string] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Pattern Compilation


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)_compilePattern {
  if ([_patternString length] == 0) {
    return;
  }

  NSMutableArray* tokens = [[NSMutableArray alloc] init];
  NSMutableSet* inboundParameters = [[NSMutableSet alloc] init];
  NSMutableSet* outboundParameters = [[NSMutableSet alloc] init];

  // Scan through the string, creating tokens that are either strings or parameters.
  // Parameters are surrounded by parenthesis and must not be nested.
  NSScanner* scanner = [NSScanner scannerWithString:_patternString];
  // NSScanner skips whitespace and newlines by default (not ideal!).
  [scanner setCharactersToBeSkipped:nil];
  while (![scanner isAtEnd]) {
    NSString* token = nil;
    [scanner scanUpToString:@"(" intoString:&token];

    if ([token length] > 0) {
      NSAssert([token rangeOfString:@")"].length == 0, @"A dangling parenthesis was found.");

      [tokens addObject:token];
    }

    if (![scanner isAtEnd]) {
      // Skip the opening bracket.
      [scanner setScanLocation:[scanner scanLocation] + 1];

      [scanner scanUpToString:@")" intoString:&token];

      NSAssert(![scanner isAtEnd], @"A parameter was not properly terminated with a closing ).");
      NSAssert([token length] > 0, @"A parameter was empty.");
      NSAssert([token rangeOfString:@"("].length == 0, @"Nested parenthesis are not permitted.");

      SOCParameter* parameter = [SOCParameter parameterWithString:token];
      if ([parameter isInbound]) {
        [inboundParameters addObject:parameter];
      } else {
        [outboundParameters addObject:parameter];
      }
      [tokens addObject:parameter];

      // Skip the closing bracket.
      [scanner setScanLocation:[scanner scanLocation] + 1];
    }
  }

  // Enforce one of only inbound, only outbound, or no parameters.
  NSAssert([inboundParameters count] > 0 && [outboundParameters count] == 0
           || [inboundParameters count] == 0 && [outboundParameters count] > 0
           || [inboundParameters count] == 0 && [outboundParameters count] == 0,
           @"All parameters must either be inbound or outbound in the pattern string: \"%@\".", _patternString);

  // This is an outbound pattern.
  if ([outboundParameters count] > 0) {
    BOOL lastWasParameter = NO;
    for (id token in tokens) {
      if ([token isKindOfClass:[SOCParameter class]]) {
        NSAssert(!lastWasParameter, @"Outbound parameters must be separated by non-parameter strings.");
        lastWasParameter = YES;

      } else {
        lastWasParameter = NO;
      }
    }
    
    // Compile the selector.
    NSMutableString* selectorString = [[NSMutableString alloc] init];
    for (SOCParameter* parameter in _outboundParameters) {
      [selectorString appendString:parameter.string];
    }
    _outboundSelector = NSSelectorFromString(selectorString);
    [selectorString release]; selectorString = nil;
  }

  [_tokens release];
  _tokens = [tokens copy];
  [_inboundParameters release]; _inboundParameters = nil;
  if ([inboundParameters count] > 0) {
    _inboundParameters = [inboundParameters copy];
  }
  [_outboundParameters release]; _outboundParameters = nil;
  if ([outboundParameters count] > 0) {
    _outboundParameters = [outboundParameters copy];
  }
  [tokens release]; tokens = nil;
  [inboundParameters release]; inboundParameters = nil;
  [outboundParameters release]; outboundParameters = nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)doesStringConform:(NSString *)string {
  const NSInteger stringLength = [string length];
  NSInteger validUpUntil = 0;
  NSInteger matchingTokens = 0;

  NSInteger tokenIndex = 0;
  for (id token in _tokens) {

    if ([token isKindOfClass:[NSString class]]) {
      NSInteger tokenLength = [token length];
      if (validUpUntil + tokenLength > stringLength) {
        // There aren't enough characters in the string to satisfy this token.
        break;
      }
      if (![[string substringWithRange:NSMakeRange(validUpUntil, tokenLength)]
            isEqualToString:token]) {
        // The tokens don't match up.
        break;
      }

      // The string token matches.
      validUpUntil += tokenLength;
      ++matchingTokens;

    } else {
      // Look ahead for the next string token match.
      if (tokenIndex + 1 < [_tokens count]) {
        NSString* nextToken = [_tokens objectAtIndex:tokenIndex + 1];
        NSAssert([nextToken isKindOfClass:[NSString class]], @"The token following a parameter must be a string.");

        NSRange nextTokenRange = [string rangeOfString:nextToken options:0 range:NSMakeRange(validUpUntil, stringLength - validUpUntil)];
        if (nextTokenRange.length == 0) {
          // Couldn't find the next token.
          break;
        }
        if (nextTokenRange.location == validUpUntil) {
          // This parameter is empty.
          break;
        }

        validUpUntil = nextTokenRange.location;
        ++matchingTokens;

      } else {
        // Anything goes until the end of the string then.
        if (validUpUntil == stringLength) {
          // The last parameter is empty.
          break;
        }

        validUpUntil = stringLength;
        ++matchingTokens;
      }
    }
    
    ++tokenIndex;
  }
  return validUpUntil == stringLength && matchingTokens == [_tokens count];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)performSelectorOnObject:(id)object conformingString:(NSString *)matchingString {
  return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)stringFromObject:(id)object {
  if ([_tokens count] == 0) {
    return @"";
  }

  NSMutableDictionary* parameterValues =
  [NSMutableDictionary dictionaryWithCapacity:[_inboundParameters count]];
  for (SOCParameter* parameter in _inboundParameters) {
    NSString* stringValue =
    [NSString stringWithFormat:@"%@", [object valueForKeyPath:parameter.string]];
    [parameterValues setObject:stringValue forKey:parameter.string];
  }

  NSMutableString* accumulator = [[NSMutableString alloc] initWithCapacity:[_patternString length]];

  for (id token in _tokens) {
    if ([token isKindOfClass:[NSString class]]) {
      [accumulator appendString:token];

    } else {
      SOCParameter* parameter = token;
      [accumulator appendString:[parameterValues objectForKey:parameter.string]];
    }
  }

  NSString* result = nil;
  result = [[accumulator copy] autorelease];
  [accumulator release]; accumulator = nil;
  return result;
}

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SOCParameter


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  [_string release]; _string = nil;
  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithString:(NSString *)string {
  if ((self = [super init])) {
    _string = [string copy];
    [self _compileParameter];
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)parameterWithString:(NSString *)string {
  return [[[self alloc] initWithString:string] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)description {
  return [NSString stringWithFormat:
          @"Parameter: %@ %@",
          _string,
          (_isOutbound ? @"outbound" : @"inbound")];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)_compileParameter {
  if ([_string hasSuffix:@":"]) {
    _isOutbound = YES;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)string {
  return [[_string retain] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isOutbound {
  return _isOutbound;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isInbound {
  return !_isOutbound;
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
SOCArgumentType SOCArgumentTypeForTypeAsChar(char argType) {
  if (argType == 'c'
      || argType == 'i'
      || argType == 's'
      || argType == 'l'
      || argType == 'C'
      || argType == 'I'
      || argType == 'S'
      || argType == 'L') {
    return SOCArgumentTypeInteger;
    
  } else if (argType == 'q' || argType == 'Q') {
    return SOCArgumentTypeLongLong;
    
  } else if (argType == 'f') {
    return SOCArgumentTypeFloat;
    
  } else if (argType == 'd') {
    return SOCArgumentTypeDouble;
    
  } else if (argType == 'B') {
    return SOCArgumentTypeBool;
    
  } else {
    return SOCArgumentTypePointer;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
NSString* SOCStringFromStringWithObject(NSString* string, id object) {
  SOCPattern* pattern = [[SOCPattern alloc] initWithString:string];
  NSString* result = [pattern stringFromObject:object];
  [pattern release];
  return result;
}
