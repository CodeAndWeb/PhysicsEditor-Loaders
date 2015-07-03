//
//  PhysicsShapeCache.m
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

#import "PhysicsShapeCache.h"
#import "CCPhysicsShape.h"
#import "CCPhysicsBody.h"


#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#   define CGPointFromString_ CGPointFromString
#else
// well - not nice but works for now
static CGPoint CGPointFromString_(NSString* str)
{
    NSString* theString = str;
    theString = [theString stringByReplacingOccurrencesOfString:@"{ " withString:@""];
    theString = [theString stringByReplacingOccurrencesOfString:@" }" withString:@""];
    NSArray *array = [theString componentsSeparatedByString:@","];
    return CGPointMake([[array objectAtIndex:0] floatValue], [[array objectAtIndex:1] floatValue]);
}
#endif


@interface GPolygon : NSObject
{
    @public
    CGPoint *vertices;
    NSUInteger numVertices;
}
@end

@implementation GPolygon

-(void) dealloc
{
    free(vertices);
}

@end

typedef enum
{
    GFIXTURE_POLYGON,
    GFIXTURE_POLYLINE,
    GFIXTURE_CIRCLE
} GFixtureType;

/**
 * Fixture definition
 * Holds fixture data
 */
@interface GFixtureData : NSObject
{
    @public

    GFixtureType fixtureType;

    CGFloat mass;
    CGFloat elasticity;
    CGFloat friction;

    CGPoint surfaceVelocity;

    NSString *collisionGroup;
    NSString *collisionType;
    NSArray *collisionCategories;
    NSArray *collisionMask;

    BOOL isSensor;

    // for circles
    CGPoint center;
    CGFloat radius;

    // for polygons / polyline
    NSMutableArray *polygons;
    CGFloat cornerRadius;
}
@end

@implementation GFixtureData

-(id) init
{
    self = [super init];
    if(self)
    {
        polygons = [[NSMutableArray alloc] init];
    }
    return self;
}

@end



/**
 * Body definition
 * Holds the body and the anchor point
 */
@interface GBodyDef : NSObject
{
@public
    CGPoint anchorPoint;
    CCPhysicsBodyType bodyType;
    NSMutableArray *fixtures;
    BOOL affectedByGravity;
    BOOL allowsRotation;
}
@end


@implementation GBodyDef

-(id) init
{
    self = [super init];
    if(self)
    {
        fixtures = [[NSMutableArray alloc] init];
    }
    return self;
}

@end


@implementation PhysicsShapeCache
{
    NSArray *categoryNames;
    CGFloat scaleFactor;
}

+ (PhysicsShapeCache *)sharedShapeCache
{
    static PhysicsShapeCache *shapeCache = 0;
    if(!shapeCache)
    {
        shapeCache = [[PhysicsShapeCache alloc] init];
    }
    return shapeCache;
}

-(id) init
{
    self = [super init];
    if(self)
    {
        bodyDefs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(CGPoint) anchorPointForShape:(NSString*)shape
{
    GBodyDef *bd = [bodyDefs objectForKey:shape];
    assert(bd);
    return bd->anchorPoint;
}


+(void) setProperties:(GFixtureData *)fixture onShape:(CCPhysicsShape *)shape
{
    [shape setMass:fixture->mass];
    [shape setElasticity:fixture->elasticity];
    [shape setFriction:fixture->friction];
    [shape setSurfaceVelocity:fixture->surfaceVelocity];
    [shape setSensor:fixture->isSensor];
    if (fixture->collisionCategories != nil && [fixture->collisionCategories count] > 0)
    {
    [shape setCollisionCategories:fixture->collisionCategories];
    }
    if (fixture->collisionMask != nil && [fixture->collisionMask count] > 0)
    {
    [shape setCollisionMask:fixture->collisionMask];
    }
    if (fixture->collisionGroup != nil)
    {
        [shape setCollisionGroup:fixture->collisionGroup];
    }
    if (fixture->collisionType != nil)
    {
        [shape setCollisionType:fixture->collisionType];
    }
}


-(CCPhysicsBody *) createBodyWithName:(NSString*)name
{
    GBodyDef *bd = [bodyDefs objectForKey:name];
    NSAssert(bd != 0, @"Body not found");
    if(!bd)
    {
        return 0;
    }

    NSMutableArray *shapes = [NSMutableArray array];
    // iterate over fixtures
    for(GFixtureData *fd in bd->fixtures)
    {
        if(fd->fixtureType == GFIXTURE_CIRCLE)
        {
            CCPhysicsShape *shape = [CCPhysicsShape circleShapeWithRadius:fd->radius center:fd->center];
            [PhysicsShapeCache setProperties:fd onShape:shape];
            [shapes addObject:shape];
        }
        else if (fd->fixtureType == GFIXTURE_POLYLINE)
        {
            // first poligon is hull
            GPolygon *hull = fd->polygons[0];
            for(int i = 0; i < hull->numVertices; i++)
            {
                CCPhysicsShape *shape = [CCPhysicsShape pillShapeFrom:hull->vertices[i] to:hull->vertices[(i+1) % hull->numVertices] cornerRadius:fd->cornerRadius];
                [PhysicsShapeCache setProperties:fd onShape:shape];
                [shapes addObject:shape];
            }
        }
        else
        {
            NSAssert(fd->fixtureType == GFIXTURE_POLYGON, @"Unknown fixture type");
            // iterate over polygons
            for(GPolygon *p in fd->polygons)
            {
                CCPhysicsShape *shape = [CCPhysicsShape polygonShapeWithPoints:p->vertices count:p->numVertices cornerRadius:fd->cornerRadius];
                [PhysicsShapeCache setProperties:fd onShape:shape];
                [shapes addObject:shape];
            }
        }
    }
    CCPhysicsBody *body =[CCPhysicsBody bodyWithShapes:shapes];
    body.affectedByGravity = bd->affectedByGravity;
    body.allowsRotation = bd->allowsRotation;
    body.type = bd->bodyType;
    return body;
}

-(void) setBodyWithName:(NSString *)name onNode:(CCNode *)node
{
    node.physicsBody = [self createBodyWithName:name];
    node.anchorPoint = [self anchorPointForShape:name];
}

-(NSArray *)categoryListFromBitfield:(uint32_t)bits
{
    NSMutableArray *names = [NSMutableArray new];
    int nameCount = MIN(32, (int)[categoryNames count]);
    for (int i = 0; i < nameCount; i++)
    {
        if (bits & (1 << i))
        {
            [names addObject:[categoryNames objectAtIndex:i]];
        }
    }
    return names;
}

-(BOOL) addShapesWithFile:(NSString*)plist
{
    NSString *path = [[NSBundle mainBundle] pathForResource:plist
                                               ofType:nil
                                          inDirectory:nil];

	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    if(!dictionary)
    {
        return FALSE;
    }

    NSDictionary *metadataDict = [dictionary objectForKey:@"metadata"];
    int format = [[metadataDict objectForKey:@"format"] intValue];

    NSAssert(format == 1, @"Format not supported");
    if(format != 1)
    {
        return FALSE;
    }

    categoryNames = [dictionary objectForKey:@"category_names"];
    scaleFactor = [[dictionary objectForKey:@"scale_factor"] floatValue];

    NSDictionary *bodyDict = [dictionary objectForKey:@"bodies"];

    for(NSString *bodyName in bodyDict)
    {
        // get the body data
        NSDictionary *bodyData = [bodyDict objectForKey:bodyName];

        // create body object
        GBodyDef *bodyDef = [[GBodyDef alloc] init];

        // add the body element to the hash
        [bodyDefs setObject:bodyDef forKey:bodyName];

        // set anchor point
        bodyDef->anchorPoint = CGPointFromString_([bodyData objectForKey:@"anchorpoint"]);
        bodyDef->affectedByGravity = [[bodyData objectForKey:@"affected_by_gravity"] boolValue];
        bodyDef->allowsRotation = [[bodyData objectForKey:@"allows_rotation"] boolValue];
        bodyDef->bodyType =[[bodyData objectForKey:@"is_static"] boolValue] ? CCPhysicsBodyTypeStatic : CCPhysicsBodyTypeDynamic;

        // iterate through the fixtures
        NSArray *fixtureList = [bodyData objectForKey:@"fixtures"];

        for(NSDictionary *fixtureData in fixtureList)
        {
            // create fixture
            GFixtureData *fd = [[GFixtureData alloc] init];
            if(!fd)
            {
                return FALSE;
            }

            // add the fixture to the body
            [bodyDef->fixtures addObject:fd];

            fd->friction = [[fixtureData objectForKey:@"friction"] floatValue];
            fd->elasticity = [[fixtureData objectForKey:@"elasticity"] floatValue];
            fd->mass = [[fixtureData objectForKey:@"mass"] floatValue];
            fd->surfaceVelocity = CGPointFromString_([fixtureData objectForKey:@"surface_velocity"]);
            fd->isSensor = [[fixtureData objectForKey:@"is_sensor"] boolValue];
            fd->cornerRadius = [[fixtureData objectForKey:@"corner_radius"] floatValue];
            fd->collisionType = [fixtureData objectForKey:@"collision_type"];
            if ([fd->collisionType length] == 0)
            {
                fd->collisionType = nil;
            }
            fd->collisionGroup = [fixtureData objectForKey:@"collision_group"];
            if ([fd->collisionGroup length] == 0)
            {
                fd->collisionGroup = nil;
            }

            uint32_t bits = [[fixtureData objectForKey:@"collision_categories"] unsignedIntValue];
            fd->collisionCategories = [self categoryListFromBitfield:bits];
            bits = [[fixtureData objectForKey:@"collision_mask"] unsignedIntValue];
            fd->collisionMask = [self categoryListFromBitfield:bits];

            NSString *fixtureType = [fixtureData objectForKey:@"fixture_type"];

            // read polygon fixtures. One convave fixture may consist of several convex polygons
            if([fixtureType isEqual:@"POLYGON"] || [fixtureType isEqual:@"POLYLINE"])
            {
                NSArray *polygonsArray = [fixtureData objectForKey:@"polygons"];

                fd->fixtureType = [fixtureType isEqual:@"POLYGON"] ? GFIXTURE_POLYGON : GFIXTURE_POLYLINE;

                for(NSArray *polygonArray in polygonsArray)
                {
                    GPolygon *poly = [[GPolygon alloc] init];
                    if(!poly)
                    {
                        return FALSE;
                    }

                    // add the polygon to the fixture
                    [fd->polygons addObject:poly];

                    // add vertices
                    poly->numVertices = [polygonArray count];
                    CGPoint *vertices = poly->vertices = malloc(sizeof(CGPoint) * poly->numVertices);
                    if(!vertices)
                    {
                        return FALSE;
                    }

                    int vindex=0;
                    for(NSString *pointString in polygonArray)
                    {
                        CGPoint offset = CGPointFromString_(pointString);
                        vertices[vindex].x = offset.x / scaleFactor;
                        vertices[vindex].y = offset.y / scaleFactor;
                        vindex++;
                    }

                }
            }
            else if([fixtureType isEqual:@"CIRCLE"])
            {
                fd->fixtureType = GFIXTURE_CIRCLE;

                NSDictionary *circleData = [fixtureData objectForKey:@"circle"];

                fd->radius = [[circleData objectForKey:@"radius"] floatValue] / scaleFactor;
                fd->center = CGPointFromString_([circleData objectForKey:@"position"]);
                fd->center.x /= scaleFactor;
                fd->center.y /= scaleFactor;
            }
            else
            {
                // unknown type
                assert(0);
            }

        }

    }

    return TRUE;
}

@end

