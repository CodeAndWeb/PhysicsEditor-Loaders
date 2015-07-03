//
//  PhysicsShapeCache.h
//
//  Loads physics sprites created with https://www.codeandweb.com/physicseditor
//
//  Shape Cache for Cocos2D V3 / Chipmunk
//
//  Copyright (c) 2015 CodeAndWeb GmbH. All rights reserved.
//  https://www.codeandweb.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "CCPhysicsBody.h"

/**
 * Shape cache
 * This class holds the shapes and makes them accessible
 * The format can be used on any MacOS/iOS system
 */
@interface PhysicsShapeCache : NSObject
{
    NSMutableDictionary *bodyDefs;
}

+ (PhysicsShapeCache *)sharedShapeCache;

/**
 * Adds shapes to the shape cache
 * @param plist name of the plist file to load
 * @result FALSE in case of error
 */
-(BOOL) addShapesWithFile:(NSString*)plist;

/**
 * Creates a body for the shape with the given name.
 * @param name name of the body
 * @result new created body
 */
-(CCPhysicsBody *) createBodyWithName:(NSString*)name;

/**
 * Creates a body for the shape with the given name,
 * and sets the body on the passed CCNode. It also sets the
 * anchor point of the node.
 * @param name name of the body
 * @param node node on which the body should be set
 */
-(void) setBodyWithName:(NSString *)name onNode:(CCNode *)node;

/**
 * Returns the anchor point of the given sprite
 * @param shape name of the shape to get the anchorpoint for
 * @return anchorpoint
 */
-(CGPoint) anchorPointForShape:(NSString*)shape;

@end
