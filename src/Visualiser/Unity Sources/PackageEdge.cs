using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class PackageEdge : MonoBehaviour{
  public static List<GameObject> allEdgeObjects = new List<GameObject>();
  public static bool EdgeViewEnabled = false;
  public (Package, Package) packEdge;
  public int weight;
  private GameObject edgePrefab;
  public static int fattestEdge = 0;
  public PackageEdge(Package p0, Package p1, int weight, GameObject prefab) {
    this.edgePrefab = prefab;
    this.packEdge = (p0, p1);
    this.weight = weight;
    fattestEdge = Mathf.Max(weight, fattestEdge);
  }

  public void spawnEdge() {
    GameObject edge = Instantiate(edgePrefab);
    Vector3 packPos1 = packEdge.Item1.instance.transform.position;
    Vector3 packPos2 = packEdge.Item2.instance.transform.position;
    edge.transform.position = packPos1 - ((packPos1 - packPos2) / 2);
    float diff = (packPos1 - packPos2).magnitude;
    float scale = (float)weight/fattestEdge * Package.fattestPackage / 10;
    // float scale = (float)weight/readFile.totalEdgesWeight*(Package.fattestPackage) + 10 / Package.fattestPackage;
    edge.transform.localScale = new Vector3(scale, scale, diff); 
    edge.transform.LookAt(packPos1);
    MeshRenderer rend = edge.GetComponent<MeshRenderer>();
    int index = (int) Mathf.Round(((float) weight / fattestEdge) * 4);
    rend.material = readFile.colors[index];

    PackageEdge pe = edge.GetComponent<PackageEdge>();
    pe.packEdge = this.packEdge;
    pe.weight = this.weight;
    
    allEdgeObjects.Add(edge);
    return;
  }

  public static void removeAllEdges() {
    foreach(GameObject edge in allEdgeObjects) Destroy(edge);
  }

  private void OnMouseDown() {
    Package.canvas.enabled = true;
    Package.packageViewEnabled = false;
    EdgeViewEnabled = true;
    Package.edgepack1.text = packEdge.Item1.packageName + " --" + weight + "--";
    Package.edgepack2.text = packEdge.Item2.packageName;
    Package.packageNameHolder.text = "";
    readFile.colourIndicator.text = "Number of shared Clone Classes";
    readFile.maxCloneHolder.text = fattestEdge.ToString();
  }
}