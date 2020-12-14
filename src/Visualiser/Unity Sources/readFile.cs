using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System.IO;

public class readFile : MonoBehaviour
{
  public float edgeWeightMult = 0.2f;
  public int initTime = 20;
  private int time = 0;
  public int type = 1;
  public userTracker user;
  public GameObject type1prefab;
  public GameObject type2prefab;
  public GameObject type3prefab;
  public GameObject packagePrefab;
  public GameObject placeHolderPrefab;
  public GameObject edgePrefab;
  public static Text maxCloneHolder;
  public static Text colourIndicator;
  public Text error;
  private List<GameObject> prefabs;
  private List<GameObject> placeHolders = new List<GameObject>();
  private string type1 = "D:\\Games\\Unity Projects\\Clone Visualisation\\type1.txt";
  private string type2 = "D:\\Games\\Unity Projects\\Clone Visualisation\\type2.txt";
  private string type3 = "D:\\Games\\Unity Projects\\Clone Visualisation\\type3.txt";
  private bool init = false;
  public static bool initDone = false;
  public static bool edgesDrawn = false;
  public static int maxLocs = 0;
  public static int totalEdgesWeight = 0;

  public Dictionary<string, List<CloneClass>> clonesPerPackage;
  // all packages = clonePerPackage.keys
  public Dictionary<(string, string), int> edgeOccurences;

  public Dictionary<string, Package> packageInstances;
  public List<GameObject> packages;
  // COLOURES
  public Material one;
  public Material two;
  public Material three;
  public Material four;
  public Material five;
  public static List<Material> colors;

  private bool built = true;
  //Package instances (name: Package)
  // Start is called before the first frame update
  private void Awake() {
    if (built) {
      type1 = Application.dataPath + "\\type1.txt";
      type2 = Application.dataPath + "\\type2.txt";
      type3 = Application.dataPath + "\\type3.txt";
    }
    colors = new List<Material>() {one, two, three, four, five};
    maxCloneHolder = GameObject.Find("maxCloneHolder").GetComponent<Text>();
    colourIndicator = GameObject.Find("colourIndicator").GetComponent<Text>();
  }
  public void Start()
  {
    foreach(GameObject package in packages) Destroy(package);
    foreach(GameObject ph in placeHolders) Destroy(ph);
    PackageEdge.removeAllEdges();
    CloneClass.removeClones();
    clonesPerPackage = new Dictionary<string, List<CloneClass>>();
    edgeOccurences = new Dictionary<(string, string), int>();
    packageInstances = new Dictionary<string, Package>();
    packages = new List<GameObject>();
    prefabs = new List<GameObject>() {type1prefab, type2prefab, type3prefab};
    Package.allEdges = new List<PackageEdge>();
    initDone = false;
    edgesDrawn = false;
    totalEdgesWeight = 0;
    Package.fattestPackage = 0;
    PackageEdge.fattestEdge = 0;
    maxLocs = 0;
    string path = getPath(type);
    readClasses(path);
    spawner();
  }

  private string getPath(int type) {
    if (type == 1) {
      return type1;
    } else if (type == 2) {
      return type2;
    } else if (type == 3) {
      return  type3;
    } else {
      Debug.LogError("Unknown clonetype: " + type + " found, file path not set");
      return null;
    }
  }


  private void readClasses(string path) {
    if (File.Exists(path)) {
      FileInfo src = new FileInfo(path);
      StreamReader reader = src.OpenText();

      string text;
      int count = 0;

      List<(string, string, string, string, string)> packagelocs = new List<(string, string, string, string, string)>();
      List<string> packagesCurrentClone = new List<string>();
      string packageName, location, before, code, after;
      do {
        text = reader.ReadLine();
        if (text != null && text.Split('^').Length>1) { // Read in a line of name^location in current clone
          string[] split = text.Split('^');
          packageName = split[0]; 
          location = split[1];
          before = split[2];
          code = split[3];
          after = split[4];
          packagesCurrentClone = setAdd<string>(packagesCurrentClone, packageName);
          packagelocs.Add((packageName, location, before, code, after));
        }

        if (text == "") { // Clone Class delimeter, so conclude the class
          CloneClass currentClone = new CloneClass(type, packagelocs, prefabs[type-1]);
          maxLocs = Mathf.Max(maxLocs, packagelocs.Count);
          addClonesToPackages(packagesCurrentClone, currentClone);

          // Keep track of the edges 
          addEdgeOccurrences(packagesCurrentClone);

          // Reset the variables used for one cloneclass
          packagelocs = new List<(string, string, string, string, string)>();
          packagesCurrentClone = new List<string>();
        }
        count++;    
      } while (text != null); 
      // Create all the packages using packagesPerClone
      createPackages();
      // Create all the edges using edgeOcurrences
      createEdges();
    } else {
      StartCoroutine("showMessage", path);
    }
    maxCloneHolder.text = maxLocs.ToString();
  }

  private void createPackages() {
    // all packages = cloneperpackage.keys
    foreach (string packageName in clonesPerPackage.Keys) {
      Package p = new Package(packageName, clonesPerPackage[packageName], packagePrefab);
      packageInstances[packageName] = p;
    }
  }

  private void createEdges() {
    // all edges = edgeOcurrences.keys
    foreach ((string, string) packageNamePair in edgeOccurences.Keys) {
      string p0 = packageNamePair.Item1;
      string p1 = packageNamePair.Item2;

      Package.allEdges.Add(new PackageEdge(packageInstances[p0], packageInstances[p1], edgeOccurences[packageNamePair], edgePrefab));
      totalEdgesWeight += edgeOccurences[packageNamePair];
    }
  }

  private void addEdgeOccurrences(List<string> packagesCurrentClone) {
    if (packagesCurrentClone.Count <= 1) return;
    
    for (int i = 0; i < packagesCurrentClone.Count-1; i++) {
      for (int j = i+1; j < packagesCurrentClone.Count; j++) {
        (string, string) sEdge = (packagesCurrentClone[i], packagesCurrentClone[j]);
        if (edgeOccurences.ContainsKey(sEdge)) {
          edgeOccurences[sEdge] += 1;
        } else {
          edgeOccurences[sEdge] = 1;
        }
      }
    }
  }

  private void addClonesToPackages(List<string> packages, CloneClass currentClone) {
    foreach (string package in packages) {
      if (clonesPerPackage.ContainsKey(package)) {
        clonesPerPackage[package].Add(currentClone);
      } else {
        clonesPerPackage[package] = new List<CloneClass>() {currentClone};
      }
    }
  }

  public List<T> setAdd<T>(List<T> list, T item) {
    if (list.Contains(item)) return list;
    list.Add(item);
    return list;
  }

  // ============================ SPAWNER ============================ 
  /// <summary> </summary>
  public void spawner() {
    int totalSize = spawnCylinder();
    spawnPackages(totalSize);
    init = true;
    userTracker.startPos = new Vector3(0, 5*Mathf.Sqrt(totalSize), 0);
    userTracker.moveToStart();
  }

  /// <summary> Spawn a cylinder with r being equal to the total length of all packages </summary>
  public int spawnCylinder() {
    int totalSize = 0;

    foreach(string name in packageInstances.Keys) {
      Package p = packageInstances[name];
      totalSize += p.classes.Count;
    }
    
    time = initTime;
    // GameObject cyl = GameObject.Instantiate(placeHolderPrefab, Vector3.zero, Quaternion.identity);
    // cyl.transform.localScale = new Vector3(3*Mathf.Sqrt(totalSize), 1, 3*Mathf.Sqrt(totalSize));
    // placeHolders.Add(cyl);
    return totalSize;
  }

  public void spawnPackages(float totalSize) {
    int packageCount = packageInstances.Keys.Count;

    int i = 0;
    foreach(Package p in packageInstances.Values) {
      float angle = i * (360 / packageCount);
      int packSize = (int) Mathf.Sqrt(p.classes.Count);
      float x = (2f*Mathf.Sqrt(totalSize) + packSize) * Mathf.Sin(angle * Mathf.Deg2Rad);
      float z = (2f*Mathf.Sqrt(totalSize) + packSize) * Mathf.Cos(angle * Mathf.Deg2Rad);
      GameObject packgo = p.spawnPackage(new Vector3(x, 0, z));
      packages.Add(packgo);
      i++;
    }
  }

  public void drawEdges() {
    foreach(PackageEdge pe in Package.allEdges) {
      pe.spawnEdge();
      edgesDrawn = true;
    }
  }

  private void FixedUpdate() {
    if (init) {
      if (time > 0) {
        // foreach(GameObject pack in packages) {
        //   Rigidbody rb = pack.GetComponent<Rigidbody>();
        //   rb.AddForce(-0.5f*rb.position, ForceMode.Impulse);
        // }
      } else {
        foreach(GameObject pack in packages) {
          Rigidbody rb = pack.GetComponent<Rigidbody>();
          rb.constraints = RigidbodyConstraints.FreezeAll;
        }
        foreach(GameObject ph in placeHolders) Destroy(ph);
        init = false;
        initDone = true;
      }
    }
    if (!edgesDrawn && initDone) {
      drawEdges();
    }
    if (time > 0) time--;
  }

  IEnumerator showMessage(string path) {
    error.text = "No information found for type" + type.ToString() + "\n@" + path + "\n\n `m` to reopen menu";
    yield return new WaitForSeconds(4.2f);
    error.text = "";
  }
}
