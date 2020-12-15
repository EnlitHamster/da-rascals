/** 
 * This is the communication protocol with the RAscal MEtrics tool.
 * Change this ONLY if you know how the saving protocol on RAMEt side
 * works.
 */

public class Bundle {
  final int[] linesOfCode;
  final int[] nTokens;
  final int rankLOC;
  final int[] CCsNE;
  final int[] CCsE;
  final int[] riskUCNE;
  final int[] riskUCE;
  final int[] ranksUC;
  final int[] USs;
  final int[] riskUS;
  final int rankUS;
  // 0 -> NUMBER OF DUPLICATE UNITS (LINES/TOKENS)
  // 1 -> NUMBER OF CLONE CLASSES
  // 2 -> BIGGEST CLONE
  // 3 -> BIGGEST CLASS
  // 4 -> NUMBER OF CLONES
  final int[] clonesType1;
  final int[] clonesType2;
  final int[] clonesType25;
  final int rankDUP;
  final int asserts;
  final int testLOC;
  final int rankTQ;
  // 0 -> ANALISABILITY
  // 1 -> CHANGEABILITY WITHOUT EXCEPTION HANDLING
  // 2 -> CHANGEABILITY WITH EXCEPTION HANDLING
  // 3 -> STABILITY
  // 4 -> TESTABILITY WITHOUT EXCPETION HANDLING
  // 5 -> TESTABILITY WITH EXCEPTION HANDLING
  // 6 -> OVERALL WITHOUT EXCEPTION HANDLING
  // 7 -> OVERALL WITH EXCEPTION HANDLING
  final int[] scores;
  
  final float[] percLOC;
  final float[] percRiskUCNE;
  final float[] percRiskUCE;
  final float[] percRiskUS;
  
  public Bundle(String[] database, boolean skipBrkts) {
      nTokens = int(split(database[0], ','));
      clonesType2 = int(split(database[1], ','));
      clonesType25 = int(split(database[2], ','));
      CCsNE = sort(int(split(database[3], ',')));
      CCsE = sort(int(split(database[4], ',')));
      riskUCNE = int(split(database[5], ','));
      riskUCE = int(split(database[6], ','));
      ranksUC = int(split(database[7], ','));
      USs = sort(int(split(database[8], ',')));
      riskUS = int(split(database[9], ','));
      rankUS = int(database[10]);
      linesOfCode = int(split(database[skipBrkts ? 11 : 12], ','));
      rankLOC = int(split(database[13], ',')[skipBrkts ? 0 : 1]);
      clonesType1 = int(split(database[skipBrkts ? 14 : 15], ','));
      rankDUP = int(split(database[16], ',')[skipBrkts ? 0 : 1]);
      scores = int(split(database[skipBrkts ? 17 : 18], ','));
      asserts = int(database[19]);
      testLOC = int(split(database[20], ',')[skipBrkts ? 0 : 1]);
      rankTQ = int(split(database[21], ',')[skipBrkts ? 0 : 1]);
      
      int totalUCNE = sum(riskUCNE);
      int totalUCE = sum(riskUCE);
      int totalUS = sum(riskUS);
      
      percLOC = new float[linesOfCode.length - 1];
      percRiskUCNE = new float[riskUCNE.length];
      percRiskUCE = new float[riskUCE.length];
      percRiskUS = new float[riskUS.length];
      
      for (int i = 0; i < linesOfCode.length - 1; i++) percLOC[i] = (float) linesOfCode[i] / (float) linesOfCode[3];
      for (int i = 0; i < riskUCNE.length; i++) percRiskUCNE[i] = (float) riskUCNE[i] / (float) totalUCNE;
      for (int i = 0; i < riskUCE.length; i++) percRiskUCE[i] = (float) riskUCE[i] / (float) totalUCE;
      for (int i = 0; i < riskUS.length; i++) percRiskUS[i] = (float) riskUS[i] / (float) totalUS; 
  }
}
