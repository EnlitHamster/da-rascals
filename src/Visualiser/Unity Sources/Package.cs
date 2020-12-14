using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Package : MonoBehaviour
{ 
  public static bool packageViewEnabled;
  public static int closeCooldown = 10;
  private static float ymult = 0.5f;
  public static List<PackageEdge> allEdges = new List<PackageEdge>();
  public userTracker user;
  public List<CloneClass> classes;
  public string packageName;
  public GameObject packagePrefab;
  public List<GameObject> cloneSpawns = new List<GameObject>();
  public static GameObject packageView;
  public static Canvas canvas;
  public static Text packageNameHolder;
  public static Text edgepack1;
  public static Text edgepack2;
  public GameObject instance;
  public static int fattestPackage = 0;

  private void Start() {
    user = GameObject.Find("User").GetComponent<userTracker>();
    packageView = GameObject.Find("PackageView");
    canvas = packageView.GetComponent<Canvas>();
    packageNameHolder = GameObject.Find("packageNameHolder").GetComponent<Text>();
    edgepack1 = GameObject.Find("EdgePack1").GetComponent<Text>();
    edgepack2 = GameObject.Find("EdgePack2").GetComponent<Text>();
  }
  public Package(string name, List<CloneClass> classes, GameObject prefab) {
    this.packageName = name;
    this.classes = classes;
    fattestPackage = (int) Mathf.Max(fattestPackage, Mathf.Sqrt(classes.Count));
    this.packagePrefab = prefab;
  }
  public GameObject spawnPackage(Vector3 pos) {
    // Spawn the package in the scene
    GameObject packgo = GameObject.Instantiate(packagePrefab);
    packgo.name = packageName;
    Rigidbody rb = packgo.GetComponent<Rigidbody>();
    rb.position = pos;
    packgo.transform.localScale = new Vector3(Mathf.Sqrt(classes.Count), ymult*Mathf.Sqrt(classes.Count), Mathf.Sqrt(classes.Count));
    Package packgoPackage = packgo.GetComponent<Package>();
    packgoPackage.classes = this.classes;
    packgoPackage.packageName = this.packageName;
    instance = packgo;
    return packgo;
  }

  public List<GameObject> spawnClasses(Vector3 parentPos) {
    foreach(GameObject cloneSpawn in cloneSpawns) Destroy(cloneSpawn);
    List<GameObject> ccgos = new List<GameObject>();

    MeshFilter[] meshFilters = new MeshFilter[classes.Count];

    float squaredCount = 0.7f * Mathf.Sqrt(classes.Count);
    Vector3 startPos = parentPos - new Vector3(squaredCount, squaredCount, squaredCount);

    int meshindex = 0;
    int i = 0;
    int j = 0;
    foreach(CloneClass cc in classes) {
      GameObject ccgo = cc.spawnClone(startPos + new Vector3(1.3f*i, -(ymult*Mathf.Sqrt(classes.Count) + 10), 1.3f*j));
      ccgos.Add(ccgo);
      cloneSpawns.Add(ccgo);
      i++;
      if (i > Mathf.Sqrt(classes.Count)) {
        i = 0;
        j++;
      }
      meshFilters[meshindex] = ccgo.GetComponent<MeshFilter>();
      meshindex++;
    }

    Vector3 pos = transform.position;
    Quaternion qas = transform.rotation;
    Vector3 sca = new Vector3(1, 1, 1);

    return ccgos;
  }

  private void OnMouseDown() {
    if (readFile.initDone) {
      canvas.enabled = true;
      packageViewEnabled = true;
      PackageEdge.EdgeViewEnabled = false;
      edgepack1.text = "";
      edgepack2.text = "";
      packageNameHolder.text = this.packageName;
      readFile.colourIndicator.text = "Instances per Clone Class";
      readFile.maxCloneHolder.text = readFile.maxLocs.ToString();
      spawnClasses(this.transform.position);
      user.moveCam(this.transform.position - new Vector3(0, ymult*Mathf.Sqrt(this.classes.Count) + 1, 0), 
                   this.transform.position - new Vector3(0, ymult*Mathf.Sqrt(this.classes.Count) + 2, 0));
    }
  }

  private void FixedUpdate() {
    if (Input.GetKey(KeyCode.Escape)) {
      if (canvas.enabled && !CloneClass.CloneClassViewEnabled 
        && closeCooldown == 0 && packageNameHolder.text == this.packageName && packageViewEnabled) {
        canvas.enabled = false;
        packageViewEnabled = false;
        PackageEdge.EdgeViewEnabled = false;
        packageNameHolder.text = "";
        userTracker.moveToStart();
        CloneClass.removeClones();
      } else if (canvas.enabled && !CloneClass.CloneClassViewEnabled 
                 && closeCooldown == 0 && PackageEdge.EdgeViewEnabled) {
        canvas.enabled = false;
        packageViewEnabled = false;
        PackageEdge.EdgeViewEnabled = false;
        packageNameHolder.text = "";
        edgepack1.text = "";
        edgepack2.text = "";
      }
    } 
    if (closeCooldown > 0) closeCooldown--;
  }

}
