package com.codeandweb.physicseditor;

import com.badlogic.gdx.math.Vector2;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.Fixture;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.utils.Array;
import com.badlogic.gdx.utils.XmlReader;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class BodyNodeTest {
  private BodyDef bodyDef;
  private World world;

  @Before
  public void setUp() throws Exception {
    bodyDef = new BodyDef();
    world = new World(new Vector2(0, 0), true);
  }

//  @Test
//  public void getAnchorPoint() throws Exception {
//
//    XmlReader xml = new XmlReader();
//    XmlReader.Element elem = xml.parse("<body name='A'><anchorpoint>1.23, 4.567</anchorpoint><fixtures/></body>");
//    BodyNode bodyNode = new BodyNode(elem);
//
//    Vector2 anchorPoint = bodyNode.anchorPoint;
//
//    assertNotNull(anchorPoint);
//    assertEquals(1.23f, anchorPoint.x, 0);
//    assertEquals(4.567f, anchorPoint.y, 0);
//  }

  @Test
  public void testCreateBody() throws Exception {
    PhysicsShapeCache shapeCache = Fixtures.load("bugs.xml");

    Body body = shapeCache.createBody("bug_0001", world, bodyDef, 1, 1);
    Array<Fixture> fixtures = body.getFixtureList();
    assertEquals(3, fixtures.size);

    Body body2 = shapeCache.createBody("bug_0001", world, bodyDef, 0.5f, 0.5f);
  }

  /**
   * This test just makes sure that all of the bodies can be created through
   * {@link PhysicsShapeCache} without raising any exceptions.
   *
   * @throws Exception
   */
  @Test
  public void testCreateAllBodies() throws Exception {
    PhysicsShapeCache shapeCache = Fixtures.load("bugs.xml");

    shapeCache.createBody("bug_0001", world, bodyDef, 1, 1);
    shapeCache.createBody("bug_0002", world, bodyDef, 1, 1);
    shapeCache.createBody("bug_0003", world, 1, 1);
    shapeCache.createBody("bug_0004", world, 1, 1);
  }
}
