// By Felix Menard from https://www.openprocessing.org/sketch/24927

void drawRect(int x1,int y1,int w1, int h1, float value, float total, color clr){
  stroke(1);
  fill(clr);
  rect(x1, y1, w1, h1); //we draw a rectangle    
  fill(1);
  String myPcntStr ;
  int myPcnt = int(round ((value / total) *100)) ;
  
  float myPcntDecimal = int(round ((value / total) *1000)) ;
  myPcntDecimal = myPcntDecimal/10;
  
  if (myPcntDecimal > 10) //bigger than 10%, we round it up.
    myPcntStr = str(myPcnt) + "%";
  else 
    myPcntStr = str(myPcntDecimal) + "%";
  
  // Rotation fix by Sandro Massa
  if (myPcntDecimal > 0.0) {
    float wPcnt = textWidth(myPcntStr);
    float hPcnt = textAscent() + textDescent();
    fill(color(0,0,0));
    if (h1 > w1) {
      pushMatrix();
      translate(x1+(w1/2)-hPcnt/4, y1+(h1/2)-wPcnt/2);
      rotate(HALF_PI);
      text(myPcntStr, 0, 0);
      popMatrix();
    } else text(myPcntStr, x1+(w1/2)-10, y1+(h1/2)+5);
  }
}

////////////////////////////////////////////////////////
///   FIND GOOD SPLIT NUMBER - advantagous block aspect ratio.
////////////////////////////////////////////////////////
int getPerfectSplitNumber(float[] numbers, int blockW, int blockH){
  // This is where well'll need to calculate the possibilities
  // We'll need to calculate the average ratios of created blocks.
  // For now we just try with TWO for the sake of the new functionn...
  
  //Let's just split in either one or two to start...
  
  float valueA = numbers[0];//our biggest value
  float valueB = 0.0;//value B will correspond to the sum of all remmaining objects in array
  for( int i=1; i < numbers.length; i++ )
    valueB += numbers[i];
  
  float ratio = valueA / (valueB + valueA);
  
  int heightA, widthA;
  if(blockW >= blockH){
    heightA = blockH;
    widthA  = floor(blockW * ratio);
  }else {
    heightA = floor(blockH * ratio);
    widthA  = blockW;
  }
  
  float ratioWH = float(widthA) / float(heightA) ;
  float ratioHW = float(heightA) / float(widthA);
  float diff;
  
  if(widthA >= heightA) // Larger rect //ratio = largeur sur hauteur,
  //we should spit vertically...
    diff = 1 - ratioHW ;
  else //taller rectangle ratio
    diff = 1- ratioWH;
  
  if((diff > 0.5) && (numbers.length >= 3)) //this is a bit elongated (bigger than 2:1 ratio)
    return 2; //TEMPORARY !!!!
  else //it's a quite good ratio! we don't touch it OR, it's the last one, sorry, no choice.
    return 1;
  
  //diff is the difference (between 0...1) to the square ratio.
  // 0 mean we have a square (don't touch, it's beautifull!)
  // 0.9 mean we have a very long rectangle.
}

////////////////////////////////////////////////////////
///   MAKE BLOCK
////////////////////////////////////////////////////////
void makeBlock(int refX, int refY, int blockW, int blockH, float[] numbers, float total, color[] clrs){
  // We sort the received array.
  ///////////////////////////////////////////////////////////////
  numbers = reverse(sort(numbers));// we sort the array from biggest to smallest value.
  
  //First we need to asses the optimal number of item to be used for block A
  // How do we do that?
  int nbItemsInABlock = getPerfectSplitNumber(numbers, blockW, blockH); //return the numbers of elements that should be taken for A block. 
   
  float valueA = 0;//the biggest value
  float valueB = 0;//value B will correspond to the sum of all remmaining objects in array
  float[] numbersA = { }; //in the loop, we'll populate these two out of our main array.
  float[] numbersB = { }; 
  color[] colorsA = { };
  color[] colorsB = { };
   
  for( int i=0; i < numbers.length; i++ ) {
    if(i < nbItemsInABlock){//item has to be placed in A array...
      numbersA = append(numbersA, numbers[i]);
      colorsA = append(colorsA, clrs[i]);
      //we populate our new array of values, we'll send it recursivly...
      valueA += numbers[i];
    }else{
      numbersB = append(numbersB, numbers[i]);
      colorsB = append(colorsB, clrs[i]); 
      //we populate our new array of values, we'll send it recursivly...
      valueB += numbers[i];
    }
  }
  float ratio = valueA / (valueB + valueA);
  
  //now we split the block in two according to the right ratio...
  
  /////////////// WE SET THE X, Y, WIDTH, AND HEIGHT VALUES FOR BOTH RECTANGLES.
  
  int xA, yA, heightA, widthA, xB ,yB, heightB, widthB;
  if(blockW > blockH){ //si plus large que haut...
    //we split vertically; so height will stay the same...
    xA = refX;
    yA = refY;// we draw the square in top right corner, so same value.
    heightA = blockH;
    widthA  = floor(blockW * ratio);
    
    xB = refX + widthA;
    yB = refY;
    heightB = blockH;
    widthB = blockW - widthA; //the remaining portion of the width...
  }else{//tall rectangle, we split horizontally.
    xA = refX;
    yA = refY;// we draw the square in top right corner, so same value.
    heightA = floor(blockH * ratio);
    widthA  = blockW;
    
    xB = refX;
    yB = refY+ heightA;
    heightB = blockH - heightA;
    widthB = blockW; //the remaining portion of the width...
  }
  
  /////////////// END OF Block maths.
  
  // if the ratio of the A block is too small (elongated rectangle)
  // we take an extra value for the A sqare, don't draw it, then send the 2 element 
  // it represents to this function (treat it recusvily as if it was a B block).
  // We dont care about the ratio of B block because they are divided after...
  
  // We add the block A to the display List
  // for now, we just draw the thing, let's convert to OOP later...
  
  if(numbersA.length >= 2) //this mean there is still stuff in this arary...
    makeBlock(xA, yA, widthA, heightA, numbersA, total, colorsA);
  else
  //if it's done, we add the B to display list, and that's it for recussivity, we return to main level... 
  // the main function will then deal with all the data...
    drawRect(xA, yA, widthA, heightA, valueA, total, colorsA[0]);
  
  if(numbersB.length >= 2) //this mean there is still stuff in this arary...
    makeBlock(xB, yB, widthB, heightB, numbersB, total, colorsB);
  else
  //if it's done, we add the B to display list, and that's it for recussivity, we return to main level... 
  // the main function will then deal with all the data...
    drawRect(xB, yB, widthB, heightB, valueB, total, colorsB[0]);
  
  //If it represent more than one value, we send the block B to be split again (recursivly)
}
