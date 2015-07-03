//
//  PhysicsShapeCache.cpp
//
//  Shape cache for Cocos2d-x (v3.x) with built-in physics classes.
//
//  Loads physics sprites created with https://www.codeandweb.com/physicseditor
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

#include "PhysicsShapeCache.h"


PhysicsShapeCache::PhysicsShapeCache()
{
}


PhysicsShapeCache::~PhysicsShapeCache()
{
    removeAllShapes();
}


PhysicsShapeCache *PhysicsShapeCache::getInstance()
{
    static PhysicsShapeCache instance;
    return &instance;
}


bool PhysicsShapeCache::addShapesWithFile(const std::string &plist)
{
    float scaleFactor = Director::getInstance()->getContentScaleFactor();
    return addShapesWithFile(plist, scaleFactor);
}


bool PhysicsShapeCache::addShapesWithFile(const std::string &plist, float scaleFactor)
{
    ValueMap dict = FileUtils::getInstance()->getValueMapFromFile(plist);
    if (dict.empty())
    {
        // plist file not found
        return false;
    }

    ValueMap &metadata = dict["metadata"].asValueMap();
    int format = metadata["format"].asInt();
    if (format != 1)
    {
        CCASSERT(format == 1, "format not supported!");
        return false;
    }

    ValueMap &bodydict = dict.at("bodies").asValueMap();
    for (auto iter = bodydict.cbegin(); iter != bodydict.cend(); ++iter)
    {
        const ValueMap &bodyData = iter->second.asValueMap();
        std::string bodyName = iter->first;
        BodyDef *bodyDef = new BodyDef();
        bodyDefs.insert(bodyName, bodyDef);
        bodyDef->anchorPoint          = PointFromString(bodyData.at("anchorpoint").asString());
        bodyDef->isDynamic            = bodyData.at("is_dynamic").asBool();
        bodyDef->affectedByGravity    = bodyData.at("affected_by_gravity").asBool();
        bodyDef->allowsRotation       = bodyData.at("allows_rotation").asBool();
        bodyDef->linearDamping        = bodyData.at("linear_damping").asFloat();
        bodyDef->angularDamping       = bodyData.at("angular_damping").asFloat();
        bodyDef->velocityLimit        = bodyData.at("velocity_limit").asFloat();
        bodyDef->angularVelocityLimit = bodyData.at("angular_velocity_limit").asFloat();

        const ValueVector &fixtureList = bodyData.at("fixtures").asValueVector();
        for (auto &fixtureitem : fixtureList)
        {
            FixtureData *fd = new FixtureData();
            bodyDef->fixtures.pushBack(fd);
            auto &fixturedata = fixtureitem.asValueMap();
            fd->density         = fixturedata.at("density").asFloat();
            fd->restitution     = fixturedata.at("restitution").asFloat();
            fd->friction        = fixturedata.at("friction").asFloat();
            fd->tag             = fixturedata.at("tag").asInt();
            fd->group           = fixturedata.at("group").asInt();
            fd->categoryMask    = fixturedata.at("category_mask").asInt();
            fd->collisionMask   = fixturedata.at("collision_mask").asInt();
            fd->contactTestMask = fixturedata.at("contact_test_mask").asInt();

            std::string fixtureType = fixturedata.at("fixture_type").asString();
            if (fixtureType == "POLYGON")
            {
                fd->fixtureType = FIXTURE_POLYGON;
                const ValueVector &polygonsArray = fixturedata.at("polygons").asValueVector();
                for (auto &polygonitem : polygonsArray)
                {
                    Polygon *poly = new Polygon();
                    fd->polygons.pushBack(poly);
                    auto &polygonArray = polygonitem.asValueVector();
                    poly->numVertices = (int)polygonArray.size();
                    auto *vertices = poly->vertices = new cocos2d::Point[poly->numVertices];
                    int vindex = 0;
                    for (auto &pointString : polygonArray)
                    {
                        auto offset = PointFromString(pointString.asString());
                        vertices[vindex].x = offset.x / scaleFactor;
                        vertices[vindex].y = offset.y / scaleFactor;
                        vindex++;
                    }
                }
            }
            else if (fixtureType == "CIRCLE")
            {
                fd->fixtureType = FIXTURE_CIRCLE;
                const ValueMap &circleData = fixturedata.at("circle").asValueMap();
                fd->radius = circleData.at("radius").asFloat() / scaleFactor;
                fd->center = PointFromString(circleData.at("position").asString()) / scaleFactor;
            }
            else
            {
                // unknown type
                return false;
            }

        }
    }
    return true;
}


BodyDef *PhysicsShapeCache::getBodyDef(const std::string &name)
{
    BodyDef *bd = bodyDefs.at(name);
    if (!bd)
    {
        bd = bodyDefs.at(name.substr(0, name.rfind('.'))); // remove file suffix and try again...
    }
    return bd;
}


void PhysicsShapeCache::setBodyProperties(PhysicsBody *body, BodyDef *bd)
{
    body->setGravityEnable(bd->affectedByGravity);
    body->setDynamic(bd->isDynamic);
    body->setRotationEnable(bd->allowsRotation);
    body->setLinearDamping(bd->linearDamping);
    body->setAngularDamping(bd->angularDamping);
    body->setVelocityLimit(bd->velocityLimit);
    body->setAngularVelocityLimit(bd->angularVelocityLimit);
}


void PhysicsShapeCache::setShapeProperties(PhysicsShape *shape, FixtureData *fd)
{
    shape->setGroup(fd->group);
    shape->setCategoryBitmask(fd->categoryMask);
    shape->setCollisionBitmask(fd->collisionMask);
    shape->setContactTestBitmask(fd->contactTestMask);
    shape->setTag(fd->tag);
}


PhysicsBody *PhysicsShapeCache::createBodyWithName(const std::string &name)
{
    BodyDef *bd = getBodyDef(name);
    if (!bd)
    {
        return 0; // body not found
    }
    PhysicsBody *body = PhysicsBody::create();
    setBodyProperties(body, bd);

    for (auto fd : bd->fixtures)
    {
        PhysicsMaterial material(fd->density, fd->restitution, fd->friction);
        if (fd->fixtureType == FIXTURE_CIRCLE)
        {
            auto shape = PhysicsShapeCircle::create(fd->radius, material, fd->center);
            setShapeProperties(shape, fd);
            body->addShape(shape);
        }
        else if (fd->fixtureType == FIXTURE_POLYGON)
        {
            for (auto polygon : fd->polygons)
            {
                auto shape = PhysicsShapePolygon::create(polygon->vertices, polygon->numVertices, material, fd->center);
                setShapeProperties(shape, fd);
                body->addShape(shape);
            }
        }
    }
    return body;
}


bool PhysicsShapeCache::setBodyOnSprite(const std::string &name, Sprite *sprite)
{
    PhysicsBody *body = createBodyWithName(name);
    if (body)
    {
        sprite->setPhysicsBody(body);
        // Cocos2d-x 3.7 required for custom anchor points:
        sprite->setAnchorPoint(getBodyDef(name)->anchorPoint);
    }
    return body != 0;
}


bool PhysicsShapeCache::removeShapesWithFile(const std::string &plist)
{
    ValueMap dict = FileUtils::getInstance()->getValueMapFromFile(plist);
    if (dict.empty())
    {
        // plist file not found
        return false;
    }

    ValueMap &metadata = dict["metadata"].asValueMap();
    int format = metadata["format"].asInt();
    if (format != 1)
    {
        CCASSERT(format == 1, "format not supported!");
        return false;
    }

    ValueMap &bodydict = dict.at("bodies").asValueMap();
    for (auto iter = bodydict.cbegin(); iter != bodydict.cend(); ++iter)
    {
        std::string bodyName = iter->first;
        BodyDef *bd = bodyDefs.at(bodyName);
        if (bd != nullptr)
        {
            safeDeleteBodyDef(bd);
            bodyDefs.erase(bodyName);
        }

    }
    return true;
}


bool PhysicsShapeCache::removeAllShapes()
{
    CCLOG("%s"," PEShapeCache removeAllbodys");
    for (auto iter = bodyDefs.cbegin(); iter != bodyDefs.cend(); ++iter)
    {
        safeDeleteBodyDef(iter->second);
    }
    bodyDefs.clear();
    return true;
}


bool PhysicsShapeCache::safeDeleteBodyDef(BodyDef *bodyDef)
{
    for (auto fixturedate : bodyDef->fixtures)
    {
        for (auto polygon : fixturedate->polygons)
        {
            CC_SAFE_DELETE_ARRAY(polygon->vertices);
        }
        fixturedate->polygons.clear();
    }
    bodyDef->fixtures.clear();
    return true;
}
