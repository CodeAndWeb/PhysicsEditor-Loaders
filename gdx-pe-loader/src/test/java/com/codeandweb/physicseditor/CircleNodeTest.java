package com.codeandweb.physicseditor;

import com.badlogic.gdx.physics.box2d.Box2D;
import com.badlogic.gdx.physics.box2d.CircleShape;
import com.badlogic.gdx.utils.XmlReader;

import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import static org.junit.Assert.*;

public class CircleNodeTest {
  private CircleNode circleNode;

  @BeforeClass
  public static void beforeAll() throws Exception {
    Box2D.init();
  }

  @Before
  public void setUp() throws Exception {
    XmlReader xml = new XmlReader();
    XmlReader.Element elem = xml.parse("<circle r='10' x='100.0' y='200.0' />");
    circleNode = new CircleNode(elem);
  }

  @Test
  public void getCircleShape() throws Exception {
    CircleShape circleShape = circleNode.getCircleShape(0.5f);

    assertNotNull(circleShape);
    assertEquals(5f, circleShape.getRadius(), 0);
    assertEquals(50f, circleShape.getPosition().x, 0);
    assertEquals(100f, circleShape.getPosition().y, 0);
  }
}