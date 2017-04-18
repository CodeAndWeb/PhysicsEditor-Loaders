package com.codeandweb.physicseditor;

import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.XmlReader;

class BodyNode {

  final String name;
  final BodyDef bodyDefFromXML;
  final Array<FixtureNode> fixtures;

  BodyNode(XmlReader.Element data) {
    // body name
    name = data.getAttribute("name");

    // BodyDef properties
    bodyDefFromXML = new BodyDef();
    bodyDefFromXML.allowSleep = data.getChildByName("allow_sleep") != null;
    bodyDefFromXML.fixedRotation = data.getChildByName("fixed_rotation") != null;
    bodyDefFromXML.bullet = data.getChildByName("is_bullet") != null;
    bodyDefFromXML.type = data.getChildByName("is_dynamic") != null ? BodyDef.BodyType.DynamicBody : BodyDef.BodyType.StaticBody;
    bodyDefFromXML.linearDamping = data.getFloat("linear_damping");
    bodyDefFromXML.angularDamping = data.getFloat("angular_damping");

    // <fixture> child elements
    Array<XmlReader.Element> fixtureElems = data.getChildrenByName("fixture");
    fixtures = new Array<FixtureNode>(fixtureElems.size);
    for (XmlReader.Element elem : fixtureElems)
      fixtures.add(new FixtureNode(elem));
  }


  Body createBody(World world, float scaleX, float scaleY) {
    return createBody(world, bodyDefFromXML, scaleX, scaleY);
  }


  Body createBody(World world, BodyDef bodyDef, float scaleX, float scaleY) {
    Body body = world.createBody(bodyDef);
    for (FixtureNode fixture : fixtures)
      fixture.addToBody(body, scaleX, scaleY);
    return body;
  }

  void dispose() {
    for (FixtureNode fixture : fixtures) {
      fixture.dispose();
    }
  }
}
