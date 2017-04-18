package com.codeandweb.physicseditor;

import org.junit.Test;

import static org.junit.Assert.*;

public class MetadataNodeTest {
  @Test
  public void testLoadsMetadata() {
    ShapeCache shapeCache = Fixtures.load("bugs");

    assertEquals(32, shapeCache.getPTM(), 1);
  }
}
