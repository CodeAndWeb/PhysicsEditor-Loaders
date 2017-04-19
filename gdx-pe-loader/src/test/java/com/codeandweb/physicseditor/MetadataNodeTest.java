package com.codeandweb.physicseditor;

import org.junit.Test;

import static org.junit.Assert.*;

public class MetadataNodeTest {
  @Test
  public void testLoadsMetadata() {
    PhysicsShapeCache shapeCache = Fixtures.load("bugs.xml");

    assertEquals(32, shapeCache.getPTM(), 1);
  }
}
