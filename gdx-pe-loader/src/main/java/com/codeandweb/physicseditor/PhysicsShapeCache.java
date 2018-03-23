package com.codeandweb.physicseditor;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.physics.box2d.Body;
import com.badlogic.gdx.physics.box2d.BodyDef;
import com.badlogic.gdx.physics.box2d.World;
import com.badlogic.gdx.utils.SerializationException;
import com.badlogic.gdx.utils.XmlReader;
import java.io.IOException;


public class PhysicsShapeCache {

  private BodyDefNode bodyDefNode;

  /**
   * Creates a new instance of ShapeCache and loads the passed PhysicsEditor XML file
   * containing the body + fixture definitions.
   *
   * @param file Handle of the XML file
   * @throws SerializationException if XML data file cannot be loaded or parsed
   */
  public PhysicsShapeCache(FileHandle file) throws SerializationException {
    try {
      XmlReader reader = new XmlReader();
      XmlReader.Element rootNode = reader.parse(file);

      bodyDefNode = new BodyDefNode(rootNode);
    } catch (SerializationException e) {
      e.printStackTrace();
      throw new SerializationException("failed to load physics shapes XML", e);
    }
  }

  /**
   * Creates a new instance of ShapeCache and loads the passed PhysicsEditor XML file
   * containing the body + fixture definitions.
   *
   * @param internalPath Internal file path of the XML file
   */
  public PhysicsShapeCache(String internalPath) throws SerializationException {
    this(Gdx.files.internal(internalPath));
  }

  /**
   * Creates a Box2D body, using the fixture definitions loaded from file.
   *
   * @param name    The name of the body exactly as it appears in the XML file.
   * @param world   The Box2D world to use to create the body.
   * @param bodyDef The body's attributes. The body attributes loaded from XML are ignored
   * @param scaleX  Scale for the fixture widths.
   * @param scaleY  Scale for the fixture heights, ignored for circles.
   * @return A Box2D body.
   */
  public Body createBody(String name, World world, BodyDef bodyDef, float scaleX, float scaleY) {
    BodyNode bodyNode = bodyDefNode.bodies.get(name);
    return bodyNode == null ? null : bodyNode.createBody(world, bodyDef, scaleX, scaleY);
  }


  /**
   * Creates a Box2D body, using the body + fixture definitions loaded from file.
   *
   * @param name    The name of the body exactly as it appears in the XML file.
   * @param world   The Box2D world to use to create the body.
   * @param scaleX  Scale for the fixture widths.
   * @param scaleY  Scale for the fixture heights, ignored for circles.
   * @return A Box2D body.
   */
  public Body createBody(String name, World world, float scaleX, float scaleY) {
    BodyNode bodyNode = bodyDefNode.bodies.get(name);
    return bodyNode == null ? null : bodyNode.createBody(world, scaleX, scaleY);
  }

  /**
   * Checks if the supplied body name is present in the XML file.
   *
   * @param name The name of the body.
   * @return Whether or not the name is present.
   */
  public boolean contains(String name) {
    return bodyDefNode.bodies.get(name) != null;
  }

  /**
   * Gets the pixels-per-meter ratio.
   *
   * @return PTM
   */
  public float getPTM() {
    return bodyDefNode.metadata.ptmRatio;
  }


  /**
   * Releases the Shape objects which have been created when loading the XML file.
   * To avoid memory leaks you have to call this method if the ShapeCache instance is no longer needed.
   */
  public void dispose() {
    for (BodyNode body : bodyDefNode.bodies.values())
      body.dispose();
    bodyDefNode.bodies.clear();
  }

}
