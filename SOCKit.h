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

/**
 * A convenience method for:
 *
 * SOCPattern* pattern = [SOCPattern patternWithString:string];
 * NSString* result = [pattern stringFromObject:object];
 *
 * @see documentation for stringFromObject:
 */
NSString* SOCStringFromStringWithObject(NSString* string, id object);

/**
 * String <-> Object Coding.
 *
 * Easily extract information from strings into objects and vice versa using KVC.
 */
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

/**
 * Initialize a newly allocated pattern object with the given pattern string.
 *
 * A pattern string is a string with parameter names wrapped in parenthesis. Pattern strings
 * are classified into two categories: inbound and outbound.
 *
 * An inbound pattern can use stringFromObject: to create a string with a given object's
 * values.
 *
 * An outbound pattern can use the perform methods to extract values from the string and call
 * selectors on objects.
 *
 * Example inbound patterns:
 *
 *   api.github.com/users/(username)/gists
 *   [pattern stringFromObject:githubUser];
 *   returns: @"api.github.com/users/jverkoey/gists"
 *
 *   api.github.com/repos/(username)/(repo)/issues
 *   [pattern stringFromObject:githubRepo];
 *   returns: @"api.github.com/repos/jverkoey/sockit/issues"
 *
 * Example outbound patterns:
 *
 *   github.com/(initWithUsername:)
 *   [pattern performPatternSelectorOnObject:[GithubUser class] sourceString:@"github.com/jverkoey"];
 *   returns: an allocated, initialized, and autoreleased GithubUser object with @"jverkoey" passed
 *            to the initWithUsername: method.
 *
 *   github.com/(initWithUsername:)/(repoName:)
 *   [pattern performPatternSelectorOnObject:[GithubUser class] sourceString:@"github.com/jverkoey/sockit"];
 *   returns: an allocated, initialized, and autoreleased GithubUser object with @"jverkoey" and
 *            @"sockit" passed to the initWithUsername:repoName: method.
 *
 *   github.com/(setUsername:)
 *   [pattern performPatternSelectorOnObject:githubUser sourceString:@"github.com/jverkoey"];
 *   returns: nil because setUsername: does not have a return value. githubUser's username property
 *            is now @"jverkoey".
 */
- (id)initWithString:(NSString *)string;
+ (id)patternWithString:(NSString *)string;

/**
 * Returns YES if the given string can be used with this pattern's perform methods.
 *
 * A conforming string must exactly match all of the static portions of the pattern and provide
 * values for each of the parenthesized portions.
 *
 *      @param string  A string that may or may not conform to this pattern.
 *      @returns YES if the given string conforms to this pattern, NO otherwise.
 */
- (BOOL)doesStringConform:(NSString *)string;

/**
 * Performs this pattern's selector on the object with the matching parameter values from
 * sourceString.
 *
 *      @param object  This pattern's selector will be called on this object. If this
 *                     pattern is an initializer pattern and object is a Class then the
 *                     class will be allocated, the selector performed on the allocated
 *                     object, and the initialized object returned.
 *      @param sourceString  A string that conforms to this pattern.
 *      @returns The initialized, autoreleased object if this pattern is an initializer and
 *               object is a Class, otherwise the return value from invoking the selector.
 */
- (id)performPatternSelectorOnObject:(id)object sourceString:(NSString *)sourceString;

/**
 * Performs the given selector on the object with the matching parameter values from sourceString.
 *
 *      @param selector  The selector to perform on the object.
 *      @param object  The selector will be performed on this object.
 *      @param sourceString  A string that conforms to this pattern. The parameter values from
 *                           this string are used when performing the selector on the object.
 *      @returns The initialized, autoreleased object if the selector is an initializer and
 *               object is a Class, otherwise the return value from invoking the selector.
 */
- (id)performSelector:(SEL)selector onObject:(id)object sourceString:(NSString *)sourceString;

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
