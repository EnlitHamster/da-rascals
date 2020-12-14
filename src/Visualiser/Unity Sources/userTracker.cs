using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// ref: https://learn.unity.com/tutorial/controlling-unity-camera-behaviour#5fc3f6a3edbc2a459f91c6ae
public class userTracker : MonoBehaviour
{
  public static Vector3 startPos;
  public float speed = 20;
  private Vector3 motion;
  public float updateSpeed = 10;
  public float sensitivity = 100f;
  public float clampAngle = 80f;
  private float rotY = 0.0f; // rotation around the up/y axis
  private float rotX = 0.0f; // rotation around the right/x axis
  private bool moving = false;
  private Vector3 desiredPos;
  private Vector3 desiredLookat;
  
  // Start is called before the first frame update
  void Start()
  {
    setRotation();
  }

  // Update is called once per frame
  // ref: https://forum.unity.com/threads/flying-character.34783/
  // ref: https://answers.unity.com/questions/29741/mouse-look-script.html
  void FixedUpdate() {
    if (moving) {
      if (!Input.GetKey(KeyCode.LeftControl)) {
        this.transform.position = desiredPos;
        this.transform.LookAt(desiredLookat);
        setRotation();
      }
      moving = false;
      return;
    }
    if (!Input.GetKey(KeyCode.LeftAlt) && !moving && !CloneClass.CloneClassViewEnabled) {
      float mouseX = Input.GetAxis("Mouse X");
      float mouseY = -Input.GetAxis("Mouse Y");

      rotY += mouseX * sensitivity * Time.deltaTime;
      rotX += mouseY * sensitivity * Time.deltaTime;

      rotX = Mathf.Clamp(rotX, -clampAngle, clampAngle);

      Quaternion localRotation = Quaternion.Euler(rotX, rotY, 0.0f);
      transform.rotation = localRotation;
    }
      
    float dt = Time.deltaTime;
    float dy =  0;
    if(Input.GetKey(KeyCode.Space))
    {
      dy = speed * dt;
    }
    if(Input.GetKey(KeyCode.LeftShift))
    {
      dy -= speed * dt;
    }
    float dx = Input.GetAxis("Horizontal") * dt * speed;
    float dz= Input.GetAxis("Vertical") * dt * speed;
    transform.position += transform.TransformDirection(new Vector3(dx, dy, dz));
    // cc.Move(transform.TransformDirection(new Vector3(dx, dy, dz)));
  }

  public void setRotation() {
    Vector3 rot = transform.localRotation.eulerAngles;
    rotY = rot.y;
    rotX = rot.x;
  }
  public void moveCam(Vector3 pos, Vector3 target) {
    moving = true;
    desiredPos = pos;
    desiredLookat = target;
  }

  public static void moveToStart() {
    if (startPos != null) {
      userTracker ut = GameObject.Find("User").GetComponent<userTracker>();
      ut.moveCam(startPos, Vector3.zero);
    }
  }
}
