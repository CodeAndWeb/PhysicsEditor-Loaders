package com.codeandweb.physicseditor;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class ShapeCacheTest {
  private ShapeCache shapeCache;

  @Before
  public void beforeEach() throws Exception {
    shapeCache = Fixtures.load("bugs");
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

  @Test
  public void testMissingFile() throws Exception {
    Fixtures.load("missing");
  }

  @Test
  public void testBrokenFile() throws Exception {
    Fixtures.load("bugs.pes");
  }
}
