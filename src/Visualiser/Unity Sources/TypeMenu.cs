using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TypeMenu : MonoBehaviour
{
  public readFile filereader;
  public Canvas typeMenu;
  public Toggle type1;
  public Toggle type2;
  // public Toggle type3;
  private int cooldown = 0;

  // Update is called once per frame
  void FixedUpdate()
  {
    if (cooldown == 0 && Input.GetKey(KeyCode.M)) {
      typeMenu.enabled = !typeMenu.enabled;
      cooldown = 20;
    } else {
      if (cooldown > 0) cooldown--;
    }
  }


  public void load() {
    if (type1.isOn) {
      filereader.type = 1; 
    } else if (type2.isOn) {
      filereader.type = 2; 
    } 
    // else {
    //   filereader.type = 3; 
    // }
    filereader.Start();
    typeMenu.enabled = false;
    if (CloneClass.CloneClassViewEnabled) {
      CloneClass.CloneClassViewEnabled = false;
      CloneClass.canvas.enabled = false;
    }
    if (Package.packageViewEnabled) {
      Package.packageViewEnabled = false;
      Package.canvas.enabled = false;
    }
    // Debug.Log("LOAD " + filereader.type);
  }
}
