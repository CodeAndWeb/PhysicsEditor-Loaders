//
//  GCpShapeCache.m
//
//  Loads physics sprites created with https://www.codeandweb.com/physicseditor
//
//  Chipmunk version
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

#import "GCpShapeCache.h"

static cpFloat area(cpVect *vertices, int numVertices)
{
	cpFloat area = 0.0f;

    int r = (numVertices-1);

	area += vertices[0].x*vertices[r].y-vertices[r].x*vertices[0].y;
	for (int i=0; i<numVertices-1; ++i)
    {
		area += vertices[r-i].x*vertices[r-(i+1)].y-vertices[r-(i+1)].x*vertices[r-i].y;
	}
	area *= .5f;
	return area;
}

@interface GPolygon : NSObject
{
    @public
    cpVect *vertices;
    int numVertices;
    cpFloat area;
    cpFloat mass;
    cpFloat momentum;
}
@end

@implementation GPolygon

-(void) dealloc
{
    free(vertices);
    [super dealloc];
}

@end


/**
 * Fixture definition
 * Holds fixture data
 */
@interface GFixtureData : NSObject
{
    @public
    cpFloat mass;
    cpFloat elasticity;
    cpFloat friction;

    cpVect surfaceVelocity;

	cpCollisionType collisionType;
	cpGroup group;
	cpLayers layers;

    cpFloat area;
    cpFloat momentum;

    BOOL isSensor;

    NSMutableArray *polygons;
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

-(void) dealloc
{
    [polygons release];
    [super dealloc];
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
    NSMutableArray *fixtures;
    cpFloat mass;
    cpFloat momentum;
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

-(void) dealloc
{
    [fixtures release];
    [super dealloc];
}

@end


@implementation GCpShapeCache


+ (GCpShapeCache *)sharedShapeCache
{
    static GCpShapeCache *shapeCache = 0;
    if(!shapeCache)
    {
        shapeCache = [[GCpShapeCache alloc] init];
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

-(void) dealloc
{
    [bodyDefs release];
    [super dealloc];
}

-(CGPoint) anchorPointForShape:(NSString*)shape
{
    GBodyDef *bd = [bodyDefs objectForKey:shape];
    assert(bd);
    return bd->anchorPoint;
}


-(ChipmunkBody *) createBodyWithName:(NSString*)name inSpace:(NSMutableSet *)space withData:(void*)data
{
    return [self createBodyWithName:name inSpace:space withData:data withCollisionType:nil];
}

-(ChipmunkBody *) createBodyWithName:(NSString*)name inSpace:(NSMutableSet *)space withData:(void*)data withCollisionType:(id)collisionType {
    GBodyDef *bd = [bodyDefs objectForKey:name];
    NSAssert(bd != 0, @"Body not found");
    if(!bd)
    {
        return 0;
    }

    // create and add body to space
    ChipmunkBody *body = [[ChipmunkBody alloc] initWithMass:bd->mass andMoment:bd->momentum];

    // set the center point
    body.pos = bd->anchorPoint;

    // set the data
    body.data  = data;

    // add space to body
    //cpSpaceAddBody(space, body);

    [space addObject:body];

    // iterate over fixtures
    for(GFixtureData *fd in bd->fixtures)
    {
        // iterate over polygons
        for(GPolygon *p in fd->polygons)
        {
            // create new shape
            ChipmunkShape *shape = [ChipmunkPolyShape polyWithBody:body count:p->numVertices verts:p->vertices offset:CGPointZero];

            shape.data          = data;
            shape.elasticity    = fd->elasticity;
            shape.friction      = fd->friction;
            shape.surfaceVel    = fd->surfaceVelocity;
            if (collisionType == nil) {
                shape.collisionType = fd->collisionType;
            } else {
                shape.collisionType = collisionType;
            }
            shape.group         = fd->group;
            shape.layers        = fd->layers;
            shape.sensor        = fd->isSensor;

            [space addObject:shape];


            //            // add shape to space
            //            cpSpaceAddShape(space, shape);
        }
    }

    return body;
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

    NSDictionary *bodyDict = [dictionary objectForKey:@"bodies"];

    for(NSString *bodyName in bodyDict)
    {
        // get the body data
        NSDictionary *bodyData = [bodyDict objectForKey:bodyName];

        // create body object
        GBodyDef *bodyDef = [[[GBodyDef alloc] init] autorelease];

        // add the body element to the hash
        [bodyDefs setObject:bodyDef forKey:bodyName];

        // set anchor point
        bodyDef->anchorPoint = CGPointFromString([bodyData objectForKey:@"anchorpoint"]);

        // iterate through the fixtures
        NSArray *fixtureList = [bodyData objectForKey:@"fixtures"];

        float totalMass = 0.0f;
        cpFloat totalBodyMomentum = 0.0f;
        for(NSDictionary *fixtureData in fixtureList)
        {
            // create fixture
            GFixtureData *fd = [[[GFixtureData alloc] init] autorelease];
            if(!fd)
            {
                return FALSE;
            }

            // add the fixture to the body
            [bodyDef->fixtures addObject:fd];

            fd->friction = [[fixtureData objectForKey:@"friction"] floatValue];
            fd->elasticity = [[fixtureData objectForKey:@"elasticity"] floatValue];
            fd->mass = [[fixtureData objectForKey:@"mass"] floatValue];
            fd->surfaceVelocity = CGPointFromString([fixtureData objectForKey:@"surface_velocity"]);
            fd->layers = [[fixtureData objectForKey:@"layers"] intValue];
            fd->group = (cpGroup) [[fixtureData objectForKey:@"group"] intValue];
            fd->collisionType = (cpCollisionType) [[fixtureData objectForKey:@"collision_type"] intValue];
            fd->isSensor = [[fixtureData objectForKey:@"fixtureData"] boolValue];

            NSString *fixtureType = [fixtureData objectForKey:@"fixture_type"];

            cpFloat totalArea = 0.0f;

            // sum up total mass for the body
            totalMass += fd->mass;

            // read polygon fixtures. One convave fixture may consist of several convex polygons
            if([fixtureType isEqual:@"POLYGON"])
            {
                NSArray *polygonsArray = [fixtureData objectForKey:@"polygons"];

                for(NSArray *polygonArray in polygonsArray)
                {
                    GPolygon *poly = [[[GPolygon alloc] init] autorelease];
                    if(!poly)
                    {
                        return FALSE;
                    }

                    // add the polygon to the fixture
                    [fd->polygons addObject:poly];

                    // add vertices
                    poly->numVertices = [polygonArray count];
                    cpVect *vertices = poly->vertices = malloc(sizeof(cpVect) * poly->numVertices);
                    if(!vertices)
                    {
                        return FALSE;
                    }

                    int vindex=0;
                    for(NSString *pointString in polygonArray)
                    {
                        CGPoint offset = CGPointFromString(pointString);
                        vertices[vindex].x = offset.x;
                        vertices[vindex].y = offset.y;
                        vindex++;
                    }

                    // calculate area of the polygon (needed to calculate the mass)
                    poly->area = area(vertices, poly->numVertices);

                    // add up all area
                    totalArea += poly->area;
                }
            }
            else
            {
                // circles are not yet supported
                assert(0);
            }

            fd->area = totalArea;

            // update sub polygon's masses and momentum
            cpFloat totalFixtureMomentum = 0.0f;

            if(totalArea)
            {
                for(GPolygon *p in fd->polygons)
                {
                    // update mass
                    p->mass = (p->area * fd->mass) / fd->area;

                    // calculate momentum
                    p->momentum = cpMomentForPoly(p->mass, p->numVertices, p->vertices, CGPointZero);

                    // calculate total momentum
                    totalFixtureMomentum += p->momentum;
                }
            }
            fd->momentum = totalFixtureMomentum;
            totalBodyMomentum = totalFixtureMomentum;
        }

        // set bodies total mass
        bodyDef->mass = totalMass;
        bodyDef->momentum = totalBodyMomentum;
    }

    return TRUE;
}

@end

