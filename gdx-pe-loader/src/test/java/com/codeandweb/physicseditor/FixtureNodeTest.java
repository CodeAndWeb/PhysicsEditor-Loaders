package com.codeandweb.physicseditor;

import com.badlogic.gdx.physics.box2d.FixtureDef;
import com.badlogic.gdx.utils.XmlReader;

import org.junit.Test;

import static org.junit.Assert.*;

public class FixtureNodeTest {
  @Test
  public void getFixtureDef() throws Exception {
    FixtureNode fixtureNode = fakeFixtureNode(true);
    FixtureDef fixtureDef = fixtureNode.fixtureDef;

    assertNotNull(fixtureDef);

    assertEquals(0.1f, fixtureDef.density, 0);
    assertEquals(0.2f, fixtureDef.friction, 0);
    assertEquals(0.3f, fixtureDef.restitution, 0);
    assertEquals(1, fixtureDef.filter.categoryBits);
    assertEquals(2, fixtureDef.filter.groupIndex);
    assertEquals(3, fixtureDef.filter.maskBits);

    assertTrue(fixtureDef.isSensor);


    fixtureNode = fakeFixtureNode(false);
    assertFalse(fixtureNode.fixtureDef.isSensor);
  }

  private static FixtureNode fakeFixtureNode(boolean isSensor) {

    XmlReader xml = new XmlReader();
    XmlReader.Element elem = xml.parse(
            "<fixture>" +
            "  <density>0.1</density>" +
            "  <friction>0.2</friction>" +
            "  <restitution>0.3</restitution>" +
            "  <filter_category_bits>1</filter_category_bits>" +
            "  <filter_group_index>2</filter_group_index>" +
            "  <filter_mask_bits>3</filter_mask_bits>" +
            (isSensor ? "   <is_sensor/>" : "") +
            "  <polygons />" +
            "</fixture>");
    FixtureNode fixtureNode = new FixtureNode(elem);

    return fixtureNode;
  }
}