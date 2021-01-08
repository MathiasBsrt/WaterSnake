import processing.sound.*;
import processing.video.*;

Capture cam; //initializes cam object

color TRACKCOLOR = -3664613; // the color the camera will be tracking. currently: kinda red-ish 
int COLORTHRESHOLD = 100; //the threshold in which the tracked color is allowed to differ from the trackcolor

SoundFile song; //initializes sound
PImage bg; //the background image

ArrayList<SnakeSegment> snake = new ArrayList<SnakeSegment>();

//global variables for the foam simulation
int FOAMRATE = 20; //the rate in which new foamwaves are created
int MAXWIDTH = 30; //the maximum wideness of the foam
boolean foamPeaked = true; //true if a new foamwave hit it's peak
int newPeak = 0; //the number of frames since the last new foamwave

float moveSpeed = 0.1;// the speed at which the snake moves
int closestX = 340; //the location of the color-tracking
int closestY = 340;

int pingCount = 0; //the time since the last ping was taken
int pingX; //location of last ping
int pingY;

//the ripples that represent the pings
ArrayList<Ripple> ripples = new ArrayList<Ripple>();

//tiny bubbles that the snake leaves behind
ArrayList<Bubble> bubbles = new ArrayList<Bubble>();

class Ripple{
  int x;
  int y;
  int size;
  
  Ripple(int xIn, int yIn){
    this.x = xIn;
    this.y = yIn;
    this.size = 0;
  }
}

class SnakeSegment{
  int x;
  int y;
  int size;
  
  int foamWidth;

  SnakeSegment(int newX, int newY, int newSize, int newFoamWidth){
    this.x = newX;
    this.y = newY;
    this.size = newSize;
    this.foamWidth = newFoamWidth;
  }
  
  SnakeSegment clone(){
     return new SnakeSegment(this.x, this.y, this.size, this.foamWidth);
  }
}

class Bubble{
  int x;
  int y;
  int size;
  int age = 0;
  boolean popping = false;
  int popCount = 0;
  
  Bubble(int x, int y, int size){
    this.x = x;
    this.y = y;
    this.size = size;
  }
}

void setup() {

  size(1280, 720);

//initializing video capture
  cam = new Capture(this, 1280, 720);
  cam.start();
  smooth();

  // The background image must be the same size as the parameters
  // into the size() method. In this program, the size of the image
  // is 682 x 682 pixels.
  bg = loadImage("water_Background.png");

//setting up snake+foam+ripples
  setupSnake(60, 50);
  ripple();
  
  //initializing sound playback. comment this out for testing as it will reduce load times
  song = new SoundFile(this, "Calm Seashore - No Copyright Sound Effects - Audio Library.mp3");
  song.loop();
}

void draw() {

  //Simulation Part
  //trackCam();

//uncomment this for testing
  /*System.out.println("x=" + closestX);
   System.out.println("y=" + closestY);*/
   
  //to avoid frame-wise flickering, the camera is only called every 2 frames. this also reduces lag
  //this needs to be called within the draw function, as calling it within the captureEvent causes weird problems withe matrices
  if(pingCount % 2 == 0){ 
    trackCam();
  }

  moveFoam();
  
  pingCount++;

  if (pingCount >= frameRate/3) {
    
    pingX = closestX;
    pingY = closestY;
    pingCount = 0;
    ripple();
  }
  
  moveBubbles();


//Visualisation part
  background(bg);

  drawRipple();
  
  drawBubbles();

  drawSnake();

  moveToCursor();
}

//searches the camera image for all pixels which color values are within a certain threshold to the trackcolor and then calculates the average
void trackCam() {
  cam.read();
  
  cam.loadPixels();

  PImage img = cam;

  pushMatrix();
  translate(img.width, 0);
  scale(-1, 1); // You had it right!*/

  float xSum = 0;
  float ySum = 0;
  int coCount = 0;

  for (int x = 0; x < img.width; x++) { // determine pixels with color
    for (int y = 0; y < img.height; y++) {
      int loc = x + y * img.width;
      color currentColor = img.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      float r2 = red(TRACKCOLOR);
      float g2 = green(TRACKCOLOR);
      float b2 = blue(TRACKCOLOR);
      float d = dist(r1, g1, b1, r2, g2, b2);
      if (d < COLORTHRESHOLD) {
        xSum += x;
        ySum += y;
        coCount++;
      }
    }
  }
  
  if(coCount > 0){
    closestX = mirrorX((int)(xSum/coCount));
    closestY = (int)(ySum/coCount);
  }
  
  popMatrix();
}


//mirrors an x-coordinate
int mirrorX(int x) {

  return 640+(640-x);
}


//un-comment this to easily determine a new color to eassily detrmine the color of a pixel if you need a new trackColor
/*void mousePressed() { // Capture color at mouse position upon mouse klick
 int loc = mouseX + mouseY*cam.width;
 trackColor = cam.pixels[loc]; 
 System.out.println(trackColor);
 }*/

//simulates the bubble movement
void moveBubbles(){
  createBubbles();
  popBubbles();
}

//creates randomly new bubbles athe "tail" of the snake
void createBubbles(){
   int rng = (int)(Math.random() * 100);
   if(rng > 20){
     int xRandom = (int)(Math.random() * 20) - 10 + snake.get(snake.size()-1).x;
     int yRandom = (int)(Math.random() * 20) - 10 + snake.get(snake.size()-1).y;
     int sizeRandom = (int)(Math.random() * 5) + 5;
     bubbles.add(new Bubble(xRandom, yRandom, sizeRandom));
  }
}

//ages the bubbles and pops some randomly
void popBubbles(){
  for(int i = 0; i < bubbles.size(); i++){
    if(!bubbles.get(i).popping){
      bubbles.get(i).age++;
      if(bubbles.get(i).age > (int)(Math.random() * 1000)){
        bubbles.get(i).popping = true;
      }
    }
    else{
      bubbles.get(i).popCount++;
      if(bubbles.get(i).popCount++ >= bubbles.get(i).size){
        bubbles.remove(i);
        i--;
      }
    }
  }
}

//draws the ittybitty bubbles
void drawBubbles(){
  stroke(#FFFFFF);
  noFill();
  
  for(int i = 0; i < bubbles.size(); i++){
    strokeWeight(bubbles.get(i).size - bubbles.get(i).popCount);
    circle(bubbles.get(i).x, bubbles.get(i).y, bubbles.get(i).size);
  }
}

//creates an array representing the centers of the circle elements, as well as their diameters
//0 = xPosition
//1 = yPosition
//2 = thickness of the circle
//EDIT: i totally forgot the word diameter yesterday, so it's always called thickness here. sorry.
void setupSnake(int length, int thick) {

  for (int i=0; i<length; i++) {
    snake.add(new SnakeSegment(150+i, 500, thick - (i/3),0));
  }
}

//draws the snake consisting of foam and water
void drawSnake() {
  drawFoam();
  drawWater();
}

//draws the circles represented by the snake array
void drawWater() {

  for (int i=0; i<snake.size() - 1; i++) {
    int offset = snake.get(i).foamWidth * 2; //the value the color of the line is offset
    stroke(color(60 + offset,60 + offset,255));
    
    strokeWeight(snake.get(i).size);
    line(snake.get(i).x, snake.get(i).y, snake.get(i+1).x, snake.get(i+1).y);
  }
}

//draws the foam around the circles in the snake array
void drawFoam() {
  stroke(#FFFFFF);

  for (int i=0; i < snake.size() - 1; i++) {
    strokeWeight(snake.get(i).foamWidth + snake.get(i).size);
    line(snake.get(i).x, snake.get(i).y, snake.get(i+1).x, snake.get(i+1).y);
  }
}


//generates the foam at start of the program
int[] generateFoam() {
  int foams[] = new int [snake.size()]; 

  for (int i = 0; i < snake.size(); i ++) {
    foams[i] = 0;
  }

  return foams;
} 

//move the foam around the snake in a wave-like fashion
void moveFoam() {

  moveTip();
  foamWave();
  moveEnd();
}

//moves the tip of the foam like the peak of a wave
void moveTip() {
  int peak = snake.get(0).foamWidth;

  if (foamPeaked) {

    newPeak = int(random(MAXWIDTH));

    foamPeaked = false;
  } else {
    if (peak == newPeak) {
      foamPeaked = true;
    } else {
      if (peak < newPeak) {
        snake.get(0).foamWidth++;
      } else {
        snake.get(0).foamWidth--;
      }
    }
  }
}

//decreses the size of the tail foam circle so that it not just flickers
void moveEnd() {
  if (snake.get(snake.size()-3).foamWidth == 0) { 
    snake.get(snake.size()-2).foamWidth--;
  } else {
    snake.get(snake.size()-2).foamWidth = snake.get(snake.size()-3).foamWidth;
  }
}

//creates a clone-ArrayList of a list of SnakeSegments
public static ArrayList<SnakeSegment> cloneList(ArrayList<SnakeSegment> list) {
    ArrayList<SnakeSegment> clone = new ArrayList<SnakeSegment>(list.size());
    for (SnakeSegment item : list) clone.add(item.clone());
    return clone;
}

//makes the foamwave move along the watersnake
void foamWave() {  
  ArrayList <SnakeSegment> cloneSnake = cloneList(snake);
  for (int i = 1; i < snake.size()-1; i++) {
    snake.get(i).foamWidth = cloneSnake.get(i-1).foamWidth;
  }
}

//moves the head of the snake towards a target
void moveToCursor() {

  int targetX = closestX;
  int targetY = closestY;  

  if (!(dist(targetX, targetY, snake.get(0).x, snake.get(0).y) < 20)) {

    snake.get(0).x = (int)((1-moveSpeed) * snake.get(0).x + moveSpeed * targetX);
    snake.get(0).y = (int)((1-moveSpeed) * snake.get(0).y + moveSpeed * targetY);

    snakeLine();
  }
}

//moves the circles of the snake tso they follow the head
void snakeLine(){
  int length = snake.size();
      for(int i=length-1; i>0; i--){
         snake.get(i).x = snake.get(i-1).x;
         snake.get(i).y = snake.get(i-1).y;
  }
}

//creates a new ripple indicator
void ripple() {
  newRipple(snake.get(0).x, snake.get(0).y);
}

//creates a new ripple at a given location
void newRipple(int newX, int newY) {
  ripples.add(new Ripple(newX, newY));
}

//draws the ripple on the canvas
void drawRipple() {
  moveRipple();

  noFill();
  strokeWeight(4);

  for (int i = 0; i < ripples.size(); i++) {
    stroke(#add8e6, 255- (ripples.get(i).size));
    circle(ripples.get(i).x, ripples.get(i).y, ripples.get(i).size );
  }
}

//increases the size of a ripple
void moveRipple() {
  for (int i= 0; i < ripples.size(); i++) {
    ripples.get(i).size += 1;
    if(ripples.get(i).size >= 255 / 2){
      ripples.remove(i); 
    }
  }
}
