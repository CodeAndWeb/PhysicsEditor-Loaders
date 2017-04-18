package com.codeandweb.physicseditor;

import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.ObjectMap;
import com.badlogic.gdx.utils.XmlReader;

class BodyDefNode {

  final ObjectMap<String, BodyNode> bodies;
  final MetadataNode metadata;


  BodyDefNode(XmlReader.Element data) {
    // load <body> elements
    Array<XmlReader.Element> bodyElements = data.getChildrenByName("body");
    bodies = new ObjectMap<String, BodyNode>(bodyElements.size * 2);
    for (XmlReader.Element elem : bodyElements) {
      BodyNode body = new BodyNode(elem);
      bodies.put(body.name, body);
    }
    // load <metadata>
    metadata = new MetadataNode(data.getChildByName("metadata"));
  }

}