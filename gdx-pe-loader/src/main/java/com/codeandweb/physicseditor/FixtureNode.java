package com.codeandweb.physicseditor;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.XmlReader;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.FixtureDef;

class FixtureNode {

  final FixtureDef fixtureDef;

  private CircleNode circleNode;
  private Array<PolygonNode> polygonNodes;

  FixtureNode(XmlReader.Element data) {

    fixtureDef = new FixtureDef();
    fixtureDef.density = data.getFloat("density");
    fixtureDef.friction = data.getFloat("friction");
    fixtureDef.restitution = data.getFloat("restitution");
    fixtureDef.filter.categoryBits = (short) data.getInt("filter_category_bits");
    fixtureDef.filter.groupIndex = (short) data.getInt("filter_group_index");
    fixtureDef.filter.maskBits = (short) data.getInt("filter_mask_bits");
    fixtureDef.isSensor = data.getChildByName("is_sensor") != null;

    XmlReader.Element circleElem = data.getChildByName("circle");
    circleNode = circleElem != null ? new CircleNode(circleElem) : null;

    Array<XmlReader.Element> polygonElems = data.getChildrenByName("polygon");
    polygonNodes = new Array<PolygonNode>(polygonElems.size);
    for (XmlReader.Element elem : polygonElems)
      polygonNodes.add(new PolygonNode(elem));

  }


  void addToBody(Body body, float scaleX, float scaleY) {

    if (circleNode != null) {
      fixtureDef.shape = circleNode.getCircleShape(scaleX);
      body.createFixture(fixtureDef);
    }

    if (polygonNodes != null) {
      for (PolygonNode polyNode : polygonNodes) {
        fixtureDef.shape = polyNode.getPolygonShape(scaleX, scaleY);
        body.createFixture(fixtureDef);
      }
    }
  }


  void dispose() {
    if (circleNode != null)
      circleNode.dispose();
    circleNode = null;

    if (polygonNodes != null)
      for (PolygonNode polyNode : polygonNodes) polyNode.dispose();
    polygonNodes = null;
  }

}