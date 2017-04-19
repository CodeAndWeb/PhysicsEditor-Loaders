package com.codeandweb.physicseditor;

import com.badlogic.gdx.utils.SerializationException;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class ShapeCacheTest {
  private PhysicsShapeCache shapeCache;

  @Before
  public void beforeEach() throws Exception {
    shapeCache = Fixtures.load("bugs.xml");
  }

  @After
  public void afterEach() {
    shapeCache.dispose();
  }

  @Test
  public void testCreateBody() {

  }

  @Test
  public void testLoadsAllBodies() throws Exception {
    assertTrue(shapeCache.contains("bug_0001"));
    assertTrue(shapeCache.contains("bug_0002"));
    assertTrue(shapeCache.contains("bug_0003"));
    assertTrue(shapeCache.contains("bug_0004"));
  }

  @Test(expected = SerializationException.class)
  public void testMissingFile() throws Exception {
    Fixtures.load("missing");
  }

  @Test(expected = SerializationException.class)
  public void testBrokenFile() throws Exception {
    Fixtures.load("bugs.pes");
  }
}
