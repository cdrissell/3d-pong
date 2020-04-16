/**
 *
 * final project
 * Cullen Drissell & Jacob Fisher
 *
 */

import processing.sound.*;
import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;

Rectangle[] face;
PFont font;

/** 
 * Paddle Tracking/Opencv Variables
 */
Capture cam;
PImage camPic;
ArrayList<PVector> cornerPoints;
PVector c1;
PVector c2;
PVector c3;
PVector c4;
OpenCV opencv;
ArrayList<PVector> lastLocs;
float x_diff;
float y_diff;

/** 
 * Scene Variables
 */
int depth;
int panelThickness;
PImage space;
PShape spaceWall;
int score = 0;
int highscore = 0;

/** 
 * Ball Variables
 */
float multiplier = 1.0;
float currentMult = multiplier;
float initialSpeed;
float vx;
float vy;
float vz;
float currentVx;
float currentVy;
float currentVz;
float speedReduction;
float ballDiameter;
float ballRadius;
float ballPosX;
float ballPosY;
float ballPosZ;
boolean halt;
boolean pause = false;
long pauseTime;

/** 
 * Paddle Variables
 */
float scaleX;
float scaleY;
float paddleX;
float paddleY;
PVector paddlePos;


/** 
 * Paddle Hit Time Variables
 */
long backNow = 0;
long leftNow = 0;
long rightNow = 0;
long topNow = 0;
long bottomNow = 0;
long paddleNow = 0;

/** 
 * Sound Variables
 */
SoundFile pongSound;
SoundFile backRsound;
SoundFile backLsound;
SoundFile backCsound;
SoundFile frontRsound;
SoundFile frontLsound;
SoundFile frontCsound;
SoundFile backSound;

/** 
 * Mode Variables
 */
int MOUSE = 1;
int PADDLE = 2;
int FACE = 3;
int mode = MOUSE; //initializes mode as mouse

boolean foundCorners = false;

void setup() {
  fullScreen(P3D);
  //size(800, 600, P3D); // for debugging

  // paddle tracking array list
  lastLocs = new ArrayList<PVector>();

  // finds multiplier for transformation between webcam and scene
  float mult = width/height;

  float captureW = 320.0;
  float captureH = captureW/mult;

  // finds scale values for paddle position
  scaleX = width/captureW;
  scaleY = height/captureH;

  cam = new Capture(this, int(captureW), int(captureH));
  cam.start();

  // initialize opencv
  opencv = new OpenCV(this, cam.width, cam.height);

  // load cascade for face detection
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);

  // initializes array list that will hold the corner points of the paddle
  cornerPoints = new ArrayList<PVector>();
  paddlePos = new PVector();
  c1 = new PVector();
  c2 = new PVector();
  c3 = new PVector();
  c4 = new PVector();

  // initializes ball and wall parameters
  depth = width;
  panelThickness = width/100;

  initialSpeed = 2*(width/150);
  ballDiameter = width/25;
  ballRadius = ballDiameter/2;

  reset();

  noCursor();
  noStroke();
  noFill();

  // sets font to chosen font
  font = loadFont("Skia-Regular_Light-Extended-48.vlw");
  textFont(font);

  // creates space background
  space = loadImage("space.jpg");
  spaceWall = createShape(RECT, -2*width, -2*height, 5*width, 5*height);
  spaceWall.setTexture(space);

  // loads sounds
  pongSound = new SoundFile(this, "pingpong.mp3");
  backRsound = new SoundFile(this, "bounceBackRight.mp3");
  backLsound = new SoundFile(this, "bounceBackLeft.mp3");
  backCsound = new SoundFile(this, "bounceBackTopBot.mp3");
  frontRsound = new SoundFile(this, "bounceFrontRight.mp3");
  frontLsound = new SoundFile(this, "bounceFrontLeft.mp3");
  frontCsound = new SoundFile(this, "bounceFrontTopBot.mp3");
  backSound = new SoundFile(this, "bounceBack.mp3");
}

// method for resetting the ball position to center and speed to 0
void reset() {
  ballPosX = width/2;
  ballPosY = height/2;
  ballPosZ = -ballDiameter;

  multiplier = currentMult;

  vx = 0.0;
  vy = 0.0;
  vz = 0.0;

  halt = true;

  score = 0;
}

// method to draw box objects in the game
void drawBox(float translateX, float translateY, float translateZ, int r, int g, int b, int w, int h, int d) {
  pushMatrix();
  translate(translateX, translateY, translateZ);
  noStroke();
  fill(r, g, b);
  box(w, h, d);
  popMatrix();
}

// method to draw the ball trackers that appear on the walls, floor, and ceiling
void drawBallTrackers() {
  int r = 0;
  int g = 0;
  int b = 0;
  // LEFT WALL TRACKER
  drawBox(-(panelThickness/2), height/2, ballPosZ, r, g, b, panelThickness+5, height, panelThickness+5);

  // RIGHT WALL TRACKER
  drawBox(width+(panelThickness/2), height/2, ballPosZ, r, g, b, panelThickness+5, height, panelThickness+5);

  // TOP WALL TRACKER
  drawBox(width/2, -(panelThickness/2), ballPosZ, r, g, b, width, panelThickness+5, panelThickness+5);

  // BOTTOM WALL TRACKER
  drawBox(width/2, height+(panelThickness/2), ballPosZ, r, g, b, width, panelThickness+5, panelThickness+5);
}


// method to update the balls position and draw the ball
void updateBall() {
  // updates ball position
  //ballPosX += multiplier*vx;
  //ballPosY += multiplier*vy;
  ballPosX += vx;
  ballPosY += vy;
  ballPosZ -= multiplier*vz;

  // DRAWS BALL
  pushMatrix();
  translate(ballPosX, ballPosY, ballPosZ);
  noStroke();
  fill(0, 255, 0);
  sphere(ballDiameter);
  popMatrix();
}

// method to draw the paddle
void drawPaddle(long time) {
  long current = millis();
  int r = 255;
  int g = 255;
  int b = 255;
  if (current - time > 150) {
    // draws paddle
    drawBox(paddleX-(width/12), paddleY, 0, r, g, b, panelThickness, width/6+(panelThickness), panelThickness);
    drawBox(paddleX+(width/12), paddleY, 0, r, g, b, panelThickness, width/6+(panelThickness), panelThickness);
    drawBox(paddleX, paddleY-(width/12), 0, r, g, b, width/6+(panelThickness), panelThickness, panelThickness);
    drawBox(paddleX, paddleY+(width/12), 0, r, g, b, width/6+(panelThickness), panelThickness, panelThickness);
    drawBox(paddleX, paddleY, 0, r, g, b, panelThickness, width/6, panelThickness);
    drawBox(paddleX, paddleY, 0, r, g, b, width/6, panelThickness, panelThickness);
  } else {
    // draws paddle when hit (fills with color)
    drawBox(paddleX-(width/12), paddleY, 0, r, g, b, panelThickness, width/6+(panelThickness), panelThickness);
    drawBox(paddleX+(width/12), paddleY, 0, r, g, b, panelThickness, width/6+(panelThickness), panelThickness);
    drawBox(paddleX, paddleY-(width/12), 0, r, g, b, width/6+(panelThickness), panelThickness, panelThickness);
    drawBox(paddleX, paddleY+(width/12), 0, r, g, b, width/6+(panelThickness), panelThickness, panelThickness);
    drawBox(paddleX, paddleY, 0, r, g, b, panelThickness, width/6, panelThickness);
    drawBox(paddleX, paddleY, 0, r, g, b, width/6, panelThickness, panelThickness);
    drawBox(paddleX, paddleY, 0, 255, 0, 255, width/6-panelThickness, width/6-panelThickness, panelThickness/2);
  }
}

// method to draw the cage lines
void drawLines() {
  int r = 140;
  int g = 100;
  int b = 150;
  // draws rings down the chamber
  for (int i = 0; i <= (2*depth); i+=(2*depth)/20) {
    drawBox(0, height/2, -i, r, g, b, panelThickness, height+panelThickness, panelThickness);
    drawBox(width, height/2, -i, r, g, b, panelThickness, height+panelThickness, panelThickness);
    drawBox(width/2, 0, -i, r, g, b, width+panelThickness, panelThickness, panelThickness);
    drawBox(width/2, height, -i, r, g, b, width+panelThickness, panelThickness, panelThickness);
  }
  // draws ceiling lines
  for (int j = 0; j <= width; j += width/((width/height)*6)) {
    drawBox(j, height, -depth, r, g, b, panelThickness, panelThickness, 2*depth);
    drawBox(j, 0, -depth, r, g, b, panelThickness, panelThickness, 2*depth);
    drawBox(j, height/2, -2*depth, r, g, b, panelThickness, height, panelThickness);
  }
  // draws wall lines
  for (int k = 0; k <= height; k += height/((width/height)*6)) {
    drawBox(0, k, -depth, r, g, b, panelThickness, panelThickness, 2*depth); 
    drawBox(width, k, -depth, r, g, b, panelThickness, panelThickness, 2*depth);
    drawBox(width/2, k, -2*depth, r, g, b, width, panelThickness, panelThickness);
  }
}


void printText(String str, int c, int size, int x, int y, int z) {
  pushMatrix();
  fill(c); 
  textSize(size);
  text(str, x, y, z); 
  popMatrix();
}


void drawAllText() {
  // prints mode
  if (mode == MOUSE) {
    printText("mouse mode", 255, width/50, -(width/12), -(height/18), 0);
  } else if (mode == PADDLE) {
    printText("paddle mode", 255, width/50, -(width/12), -(height/18), 0);
  } else if (mode == FACE) {
    printText("face mode", 255, width/50, -(width/12), -(height/18), 0);
  }
  //prints score
  printText("score: "+score, 255, width/50, width, -(height/18), 0);
  //prints fps
  printText("fps: "+int(frameRate), 255, width/50, -(width/12), height+(height/14), 0);
  //prints highscore
  printText("highscore: "+highscore, 255, width/50, width-(width/20), height+(height/14), 0);
}


void draw() {
  
  // SWITCHES BETWEEN MODES
  if (keyPressed) {
    if (key == '1') {
      reset();
      mode = MOUSE;
      multiplier = 1.0;
      currentMult = multiplier;
      //lastLocs.clear();
    } else if (key == '2') {
      reset();
      mode = PADDLE;
      multiplier = 1.0;
      currentMult = multiplier;
      //lastLocs.clear();
    } else if (key == '3') {
      reset();
      mode = FACE;
      multiplier = 2.0;
      currentMult = multiplier;
      //lastLocs.clear();
    }
  }

  // IF MOUSE MODE IS ON
  if (mode == MOUSE) {
    paddleX = mouseX;
    paddleY = mouseY;

    PVector pos = new PVector();
    pos.x = paddleX;
    pos.y = paddleY;

    lastLocs.add(pos);
    if (lastLocs.size() > 2) lastLocs.remove(0);
  } 
  // IF PADDLE MODE IS ON
  else if (mode == PADDLE) {
    opencv.loadImage(cam);
    opencv.gray();
    cornerPoints = opencv.findChessboardCorners(3, 3);

    /* // use if not using the center point correction algorithm below
     if (cornerPoints.size() >= 5) {
     paddleX = width-cornerPoints.get(4).x*scaleX;
     paddleY = cornerPoints.get(4).y*scaleY;
     }
     */

    // checks to see if we are looking at paddle
    //foundCorners = (cornerPoints.size() > 0)?true:false;
    if (cornerPoints.size() > 0) foundCorners = true;
    else foundCorners = false;

    // found the paddle
    if (foundCorners == true) {
      if (cornerPoints.size() >= 5) {
        paddlePos = cornerPoints.get(4);
        paddleX = width-(scaleX*paddlePos.x);
        paddleY = scaleY*paddlePos.y;
        // track center points
        lastLocs.add(paddlePos);
        if (lastLocs.size() > 2)
          // no need for the last last first point
          lastLocs.remove(0);
      }
    }

    //When the camera can't find the paddle
    //it continues to draw the paddle on the 
    //same trajectory that it saw earlier.
    if (foundCorners == false && lastLocs.size() > 1)
    {

      x_diff = (lastLocs.get(1).x*scaleX) - (lastLocs.get(0).x*scaleX);
      y_diff = (lastLocs.get(1).y*scaleY) - (lastLocs.get(0).y*scaleY);

      if (((paddleX - x_diff) < width || (paddleX - x_diff) > 0)  && ((paddleY - y_diff) < height || (paddleY - y_diff) > 0)) {
        paddleX -= x_diff;
        paddleY -= y_diff;
      }
      /*
      float last_x_diff = x_diff;
       float last_y_diff = y_diff;
       x_diff = lastLocs.get(1).x - lastLocs.get(0).x;
       y_diff = lastLocs.get(1).y - lastLocs.get(0).y;
       
       if (x_diff != 0 || y_diff != 0)
       {
       paddleX += x_diff;
       paddleY += y_diff;
       } else
       {
       paddleX += last_x_diff;
       paddleY += last_y_diff;
       }
       */
    }
  } 
  // IF FACE MODE IS ON
  else if (mode == FACE) {

    opencv.loadImage(cam);
    opencv.gray();
    face = opencv.detect();

    paddleX = width/2;
    paddleY = height/2;

    float X = 0;
    float Y = 0;

    // finds center point of face rectangle
    for (int i = 0; i < face.length; i++) {
      X = (width-(face[i].x*scaleX+(face[i].width*scaleX/2)));
      Y = (face[i].y*scaleY+(face[i].height*scaleY/2));
    }

    // sets paddle position to center point of face
    if (X < paddleX && X > 0) {
      float diff = abs(paddleX-X);
      paddleX -= 3*diff;
    } else if (X > paddleX && X < width) {
      float diff = abs(paddleX-X);
      paddleX += 3*diff;
    }
    if (Y < paddleY && Y > 0) {
      float diff = abs(paddleY-Y);
      paddleY -= 3*diff;
    } else if (Y > paddleY && Y < height) {
      float diff = abs(paddleY-Y);
      paddleY += 3*diff;
    }
  }

  // gets key press
  if (keyPressed) {
    if (key == 'r' || key == 'R') reset();
    if ((key == 'p' || key == 'P') && pause == false) {
      currentVx = vx;
      currentVy = vy;
      currentVz = vz;
      vx = 0;
      vy = 0;
      vz = 0;
      pause = true;
    } else if ((key == 'p' || key == 'P') && pause == true) {
      vx = currentVx;
      vy = currentVy;
      vz = currentVz;
      pause = false;
    }
  }

  if (halt == true && mousePressed) {
    halt = false;

    ballPosX = width/2;
    ballPosY = height/2;
    ballPosZ = -ballRadius-1;

    vz = initialSpeed;

    if (mode == MOUSE) {      
      
      PVector padPos1 = lastLocs.get(0);
      PVector padPos2 = lastLocs.get(1);

      float distX = padPos2.x - padPos1.x;
      float distY = padPos2.y - padPos1.y;

      vx+=(100*distX/width);
      vy+=(100*distY/height);
      
      if(vx < 0.5 && vx > -0.5) vx = initialSpeed/2;
      if(vy < 0.5 && vy > -0.5) vy = -initialSpeed/2;
      
    } else {
      if (Math.random()<0.5) {
        vx = initialSpeed;
      } else vx = -initialSpeed;
      if (Math.random()<0.5) {
        vy = initialSpeed;
      } else vy = -initialSpeed;
    }
  } else if (halt == false) {
    if (ballPosZ-ballRadius <= -2*depth) { // ball hit back wall
      vz*=-1;
      backNow = millis();
      backSound.play();
    } 
    if ( ballPosX-ballRadius <= (panelThickness/2)+2) { // ball hit left wall
      vx*=-1;
      leftNow = millis();
      if (ballPosZ < -depth) backLsound.play();
      else frontLsound.play();
    } 
    if (ballPosX+ballRadius >= width-(panelThickness/2)-2 ) { // ball hit right wall
      vx*=-1;
      rightNow = millis();
      if (ballPosZ < -depth) backRsound.play();
      else frontRsound.play();
    } 
    if (ballPosY+ballRadius >= height-(panelThickness/2)-2) { // ball hit top wall
      vy*=-1;
      topNow = millis();
      if (ballPosZ < -depth) backCsound.play();
      else frontCsound.play();
    } 
    if (ballPosY-ballRadius <= (panelThickness/2)+2) { // ball hit bottom wall
      vy*=-1;
      bottomNow = millis();
      if (ballPosZ < -depth) backCsound.play();
      else frontCsound.play();
    } 
    if (ballPosZ+ballRadius >= -(panelThickness/2) && ballPosZ-ballRadius <= 0 && // ball hit paddle
      ballPosX-ballRadius >= paddleX-(width/6) && ballPosX+ballRadius <= paddleX+(width/6) && 
      ballPosY-ballRadius >= paddleY-(width/6) && ballPosY+ballRadius <= paddleY+(width/6)) {


      if (vz < 0) vz*=-1;
      if (mode == MOUSE) {
        PVector padPos1 = lastLocs.get(0);
        PVector padPos2 = lastLocs.get(1);

        float distX = padPos2.x - padPos1.x;
        float distY = padPos2.y - padPos1.y;

        vx+=(100*distX/width);
        vy+=(100*distY/height);
      }
      score++;
      multiplier+=0.05; // CHANGES DIFFICULTY
      paddleNow = millis();
      pongSound.play();
    }
  }
  if (ballPosZ-ballRadius >= (width/4)) { // ball missed paddle
    if (score > highscore) highscore = score;
    reset();
  }

  // creates light in scene
  lights();
  pointLight(100, 100, 100, width/2, height/2, -depth);

  // draws space background
  pushMatrix();
  translate(0, 0, -2*depth);
  shape(spaceWall);
  popMatrix();

  drawPaddle(paddleNow);

  drawAllText();

  updateBall();

  if (halt == false) drawBallTrackers();

  drawLines();

  camera(width/2.0, height/2.0, ((height/2.0) / tan(PI*30.0 / 180.0))+(depth/8), width/2.0, height/2.0, 0, 0, 1, 0);
}
