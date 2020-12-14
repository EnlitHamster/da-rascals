using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class displayCloneClass : MonoBehaviour
{
  private static List<GameObject> spawns = new List<GameObject>();
  public GameObject PPL_prefab;
  public RectTransform content;
  public RectTransform Spawnpoint;
  public Text className;
  public Text pageNumbers;
  public static int offset = 0;
  private int height = 0;
  private CloneClass cc;
  public static CloneClass current;
  // Start is called before the first frame update
  void Start()
  {
    height = 0;
  }

  public void show(CloneClass cc) {
    removeSpawns();
    current = cc;
    height = 0;
    // Set name 
    className.text = "Clone Class #" + cc.id;
    Debug.Log(cc.packagelocs.Count);
    // return;
    // content.sizeDelta = new Vector2(0, cc.packagelocs.Count*height);
    int i;
    int start = offset * 100;
    int end = Mathf.Min(cc.packagelocs.Count, start + 100);
    pageNumbers.text = "(" + start + "-" + end + ") out of " + cc.packagelocs.Count;
    // add locations
    for (i = start; i < end; i++) {
      // Spawn at spawnpoint... Height = previousHeight
      Vector3 pos = new Vector3(Spawnpoint.anchoredPosition.x, Spawnpoint.anchoredPosition.y, Spawnpoint.position.z);
      GameObject cloneView = Instantiate(PPL_prefab, pos, Spawnpoint.rotation);
      RectTransform rt = cloneView.GetComponent<RectTransform>();
      // Change the height + set previousHeight
      spawns.Add(cloneView);
      
      textHolder th = cloneView.GetComponent<textHolder>();
      string package = cc.packagelocs[i].Item1;
      string location = cc.packagelocs[i].Item2;
      string before = cc.packagelocs[i].Item3;
      string code = cc.packagelocs[i].Item4;
      string after = cc.packagelocs[i].Item5;

      string[] seperators = new string[] {"\\r\\n"};
      string[] beforelines = before.Split(seperators, System.StringSplitOptions.None);
      string[] codelines = code.Split(seperators, System.StringSplitOptions.None);
      string[] afterlines = after.Split(seperators, System.StringSplitOptions.None);

      int lines = beforelines.Length + codelines.Length + afterlines.Length + 6;
      rt.sizeDelta = new Vector2(rt.sizeDelta.x, lines*16);
      // cloneView.transform.position += new Vector3(0, ,0);
      string printBefore = getPrintLine(beforelines);
      string printCode = getPrintLine(codelines);
      string printAfter = getPrintLine(afterlines);
      if (i == start) {
        cloneView.transform.position = new Vector3(Spawnpoint.anchoredPosition.x, Spawnpoint.anchoredPosition.y - height +30- (rt.sizeDelta.y/2.5f), Spawnpoint.position.z);
        height += 30;
      } else {
        cloneView.transform.position = new Vector3(Spawnpoint.anchoredPosition.x, Spawnpoint.anchoredPosition.y - height +30- (rt.sizeDelta.y/2), Spawnpoint.position.z);
      }
      if(cc.id == 96) {
        Debug.Log(height);
        Debug.Log(code);
      }
      cloneView.transform.SetParent(Spawnpoint, false);
      height += (int) rt.sizeDelta.y;
      printBefore = printBefore.Replace("\\t", "\t");
      printCode = printCode.Replace("\\t", "\t");
      printAfter = printAfter.Replace("\\t", "\t");
      th.input.text = "Package::" + package + "\nLocation::" + location + "\nCode::" + 
                      printBefore + "\nSTART OF CLONE" + printCode + "\nEND OF CLONE" + printAfter;
    }
    content.sizeDelta = new Vector2(0, height);
    height = 0;
  }

  private string getPrintLine(string[] lines) {
    string printLine = "";
    foreach(string line in lines) printLine += " \n \t" + line;
    return printLine;
  }

  public void increaseOffset() {
    offset++;
    if (offset*100 > current.packagelocs.Count) {
      offset--;
      return;
    }
    show(current);
  }

  public void decreaseOffset() {
    offset--;
    if (offset < 0) {
      offset = 0;
      return;
    }
    show(current);
  }

  // Update is called once per frame
  public static void removeSpawns() {
    foreach (GameObject g in spawns) Destroy(g);
  }
}
