package com.codeandweb.physicseditor;

import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.physics.box2d.Box2D;

import java.io.File;

public final class Fixtures {
  private static boolean box2dInitialized = false;

  /**
   * Creates a ShapeCache instance from an XML fixture found in the resources path.
   *
   * @param fixtureName The fixture's file name without a path or extension.
   * @return A {@link PhysicsShapeCache} instance.
   */
  static PhysicsShapeCache load(String fixtureName) {
    initBox2D();
    String filename = String.format("src/test/resources/%s", fixtureName);
    return new PhysicsShapeCache(new FileHandle(filename));
  }

  /**
   * Initializes Box2D if it hasn't already been.
   */
  private static void initBox2D() {
    if (!box2dInitialized) {
      Box2D.init();
      box2dInitialized = true;
    }
  }
}
