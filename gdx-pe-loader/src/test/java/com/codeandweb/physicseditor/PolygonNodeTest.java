package com.codeandweb.physicseditor;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.PolygonShape;
import com.badlogic.gdx.utils.XmlReader;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class PolygonNodeTest {
  private PolygonNode polygonNode;

  @Before
  public void setUp() throws Exception {
    XmlReader xml = new XmlReader();
    XmlReader.Element elem = xml.parse("<polygon> 1.0000, 6.0000  ,  19.0000, 6.0000  ,  16.0000, 19.0000  ,  4.0000, 19.0000 </polygon>");
    polygonNode = new PolygonNode(elem);
  }

  @Test
  public void testGetPolygonShapes() throws Exception {
    PolygonShape polygonShape = polygonNode.getPolygonShape(1, 1);

    assertNotNull(polygonShape);

    assertEquals(4, polygonShape.getVertexCount());

    Vector2 vertex = new Vector2();

    polygonShape.getVertex(0, vertex);
    assertEquals(19f, vertex.x, 0);
    assertEquals(6f, vertex.y, 0);

    polygonShape.getVertex(1, vertex);
    assertEquals(16f, vertex.x, 0);
    assertEquals(19f, vertex.y, 0);

    polygonShape.getVertex(2, vertex);
    assertEquals(4f, vertex.x, 0);
    assertEquals(19f, vertex.y, 0);

    polygonShape.getVertex(3, vertex);
    assertEquals(1f, vertex.x, 0);
    assertEquals(6f, vertex.y, 0);

    polygonShape = polygonNode.getPolygonShape(0.5f, 0.25f);

    polygonShape.getVertex(0, vertex);
    assertEquals(19f * 0.5f, vertex.x, 0);
    assertEquals(6f * 0.25f, vertex.y, 0);
  }
}