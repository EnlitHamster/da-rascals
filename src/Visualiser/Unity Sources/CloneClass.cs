using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloneClass : MonoBehaviour
{
  public static List<GameObject> CloneClassObjects = new List<GameObject>();
  public static bool CloneClassViewEnabled = false;
  public static int count = 0;
  public int id;
  public List<(string, string, string, string, string)> packagelocs;
  public bool crossPackage;
  public int type;
  public static Canvas canvas;
  public static displayCloneClass displayer;
  GameObject look;
  GameObject instance;
  // Start is called before the first frame update

  public CloneClass(int type, List<(string, string, string, string, string)> packagelocs, GameObject prefab) {
    id = count;
    // this.packagelocs = new List<(string, string)>(packagelocs);
    this.packagelocs = packagelocs;
    this.type = type;
    this.look = prefab;
    count++;
  }

  public GameObject spawnClone(Vector3 pos) {
    GameObject go = GameObject.Instantiate(this.look, pos, Quaternion.identity);
    CloneClass goclass = go.GetComponent<CloneClass>();
    goclass.id = this.id;
    goclass.packagelocs = this.packagelocs;
    goclass.type = this.type;
    this.instance = go;
    CloneClassObjects.Add(go);
    // go.GetComponent<MeshFilter>().mesh.subMeshCount = 2;
    MeshRenderer mesh = go.GetComponent<MeshRenderer>();
    Material[] materials = mesh.materials;
    int index = ((int) Mathf.Round( ((float) packagelocs.Count / readFile.maxLocs) * 4 ));
    materials[1] = readFile.colors[index];
    mesh.materials = materials;
    return go;
  }
  
  private void Awake() {
    canvas = GameObject.Find("CloneClassView").GetComponent<Canvas>();
    displayer = canvas.GetComponent<displayCloneClass>();
  }
    
  // Update is called once per frame
  private void OnMouseDown() {
    if (!canvas.enabled) {
      canvas.enabled = true;
      CloneClassViewEnabled = true;
      displayer.show(this);
      displayCloneClass.offset = 0;
    }
  }

  private void FixedUpdate() {
    if (Input.GetKey(KeyCode.Escape) && canvas.enabled) {
      canvas.enabled = false;
      CloneClassViewEnabled = false;
      Package.closeCooldown = 500;
      displayCloneClass.removeSpawns();
    }
  }

  public static void removeClones() {
    foreach(GameObject g in CloneClassObjects) Destroy(g);
  }
}
