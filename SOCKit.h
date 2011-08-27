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

#import <Foundation/Foundation.h>

NSString* SOCStringFromStringWithObject(NSString* string, id object);

@interface SOCPattern : NSObject {
@private
  NSString* _patternString;
  NSArray* _tokens;

  // Inbound
  NSSet* _inboundParameters;

  // Outbound
  NSArray* _outboundParameters;
  SEL _outboundSelector;
}

- (id)initWithString:(NSString *)string;
+ (id)patternWithString:(NSString *)string;

/**
 * Returns YES if the given string conforms to this pattern.
 *
 * A conforming string must match all of the static portions of the pattern and provide values
 * for each of the parenthesized portions.
 *
 * A conforming string can be used as the conformingString in
 * performSelectorWithObject:conformingString:.
 *
 *      @param string  A string that may or may not conform to this pattern.
 *      @returns YES if the given string conforms to this pattern, NO otherwise.
 */
- (BOOL)doesStringConform:(NSString *)string;

/**
 * Performs this pattern's selector on the object with the values retrieved from matchingString.
 *
 *      @param object  This pattern's selector will be called on this object. If this
 *                     pattern is an initializer pattern and object is a Class then the
 *                     class will be allocated, the selector performed on the allocated
 *                     object, and the initialized object returned.
 *      @param matchingString  A string that conforms to this pattern.
 *      @returns The initialized object if this pattern is an initializer and object is a Class,
 *               otherwise nil.
 */
- (id)performSelectorOnObject:(id)object conformingString:(NSString *)matchingString;

/**
 * Returns a string with the parenthesized portions of this pattern replaced using
 * Key-Value Coding (KVC) on the receiving object.
 *
 * Parenthesized portions of the pattern are evaluated using valueForKeyPath:. See Apple's
 * KVC documentation for more details.
 *
 * Key-Value Coding Fundamentals:
 * http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/KeyValueCoding/Articles/BasicPrinciples.html#//apple_ref/doc/uid/20002170-BAJEAIEE
 *
 * Collection Operators:
 * http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html#//apple_ref/doc/uid/20002176-BAJEAIEE
 */
- (NSString *)stringFromObject:(id)object;

@end
