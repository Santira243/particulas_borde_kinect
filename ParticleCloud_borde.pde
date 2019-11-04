/*
Robert Pinedo & Lali Barrière
Master thesis: Interaction for creative applications with the Kinect v2 device
Particle Cloud
Based on Diana Lange's strategy in her sketch "imageTargets"
*/
import KinectPV2.*;
KinectPV2 kinect;
import processing.sound.*;
PImage img; //starting image
PVector[] start; //initial array of positions
PVector[] end; //final array of positions
float m = 0; //used later for a sin function (with lerp, for the motion of the particles)
int row = 0; //let's try change particles size by rows
boolean check = false;//given a trigger
color col = color (255);
boolean toggle = false;
AudioIn input;
Amplitude rms;
int scale=1;
PImage newImg;
PImage edgeImg;
void setup() 
{
size(displayWidth, displayHeight, P3D);
kinect = new KinectPV2(this);
kinect.enableBodyTrackImg(true);
kinect.init();
img = loadImage("1.jpg");
newImg= img.get(0, 0, img.width, img.height);
newImg.resize(displayWidth, displayHeight);

int nDots = 400;
start = new PVector [nDots]; //2000 positions, 2000 particles
end = new PVector [nDots];
setRandomPositions (start); //it begins random
arrayCopy (start, end); //creates "end" as a copy of "start"
setNearestRandomPositions (end, end.length); //end = array, end.lenght = array length = 2000. Finds the nearest point in black color for each particle.
input = new AudioIn(this, 0); // Creates an Audio input and grabs the 1st channel
input.start(); // starts the Audio Input
rms = new Amplitude(this); // creates a new Amplitude analyzer
rms.input(input); // Patches the input to an volume analyzer
frameRate(30);
}
void draw()
{
//fill (#57385c, 80);
noStroke();
//rect (0, 0, width, height); //paints the background
background(0);
scale=int(map(rms.analyze(), 0, 0.5, 1, 424)); // rms.analyze() return a value between 0 and 1.
if (scale > 53) {
check = true;
}
//draw ellipses
fill (random(180, 255), random(180, 255), random(180, 255)); //random colors?
noStroke();
for (int i = 0; i < start.length; i++)
{
PVector current = new PVector (lerp (start[i].x, end[i].x, m), lerp (start[i].y, end[i].y, m)); //m=0, lerp = point over the straight line given by 2 other points.
noStroke();
fill (random(80, 255), random(80, 255), random(80, 255));
ellipse (current.x, current.y, 4, 4);
}
// move
m+= 0.2; //m+=0.02; // begins at 0, as it increases, the lerp makes the ellipse move between the start position and the end position
// check if target reached and set new target
if (m>=1)
{
if (kinect.getNumOfUsers()>0) 
{
  img = kinect.getBodyTrackImage();
  boolean borde;  
  edgeImg = createImage(img.width, img.height, RGB);
  // Loop through every pixel in the image.
  for (int y = 1; y < img.height-1; y++) { // Skip top and bottom edges
    for (int x = 1; x < img.width-1; x++) { // Skip left and right edges
      borde = false;
      int pos_1 = (y)*img.width + (x);
      float col = red(img.pixels[pos_1]);
      if(col < 100){
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          // Calculate the adjacent pixel for this kernel point
          int pos = (y + ky)*img.width + (x + kx);
          // Image is grayscale, red/green/blue are identical
          float val = red(img.pixels[pos]);
          // Multiply adjacent pixels based on the kernel values
          //sum += kernel[ky+1][kx+1] * val;
          if(val > 100)
          {
            borde = true;
          }
        }
      }
      // For this pixel in the new image, set the gray value
      // based on the sum from the kernel
      if(borde) {
        edgeImg.pixels[y*(img.width) + x] = color(0, 0, 0);
      }
      else{
       edgeImg.pixels[y*(img.width) + x] = color(255, 255, 255);
      }
     }
     else
     {
       edgeImg.pixels[y*(img.width) + x] = color(255, 255, 255);  
     }
    }
  }
   for (int x = 0; x < img.width; x++)  // Skip top and bottom edges
    {
     edgeImg.pixels[x] = color(255, 255, 255); 
    }
    for (int y = 0; y < img.height; y++) 
    { // Skip top and bottom edges
       edgeImg.pixels[y*(img.width)] = color(255, 255, 255); 
       if(y>0) 
       {edgeImg.pixels[y*(img.width)-1] = color(255, 255, 255);}  
 
    }  
 edgeImg.updatePixels();
  newImg= edgeImg.get(0, 0, edgeImg.width, edgeImg.height);
}
else
{
  newImg= img.get(0, 0, img.width, img.height);

}
newImg.resize(displayWidth, displayHeight);
m = 0;
arrayCopy (end, start);
setNearestRandomPositions (end, end.length);

}
if (toggle==true) {
fill(0, 255, 0);
rect(482, 10, 20, scale);
fill(255);
text("check =" + check, 20, 20);
text("frame rate =" + int(frameRate), 20, 40);
text("sound bar size = " + 1*scale, 20, 60);
}
}
void setNearestRandomPositions (PVector [] p, int num) //end & end.length (2000)
{
PVector [] randomPos = new PVector [num]; //num = 2000, creates an array of 2000 random positions
int k = 0;
while (k < num) //0 to 1999
{
PVector pos = new PVector (random (width), random (height));
if (isTarget(pos)) //isTarget? Line 76. Searches randomly a dark pixel.
{
randomPos [k] = pos; //if true (if dark), gives it the value of that position.
k = k +1;
}
}
int nearestIndex = 0; //initially 0
float nearestDistance = width*height; //initially is the maximum
for (int i = 0; i < p.length; i++) //p = end (array), p.length = 2000
{
nearestIndex = 0; //again
nearestDistance = width*height; //again
for (int j = 0; j < randomPos.length; j++) //from 0 to --> compares the random array with each point of the end array.
{
if (randomPos[j].z == -1) continue; // skips the next iteration. The first time any Z pos is -1.
float distance = dist (randomPos[j].x, randomPos[j].y, p[i].x, p[i].y); //distance between the random position and the end position.
if (distance < nearestDistance) //the first time, if that distance is < W*H
{
nearestDistance = distance; //if true, this is the new nearest distance
nearestIndex = j; //the position in the randomPos array nearest to the end array
}
}
p [i] = randomPos[nearestIndex].copy(); //"get()" is deprecated, use "copy()".

randomPos[nearestIndex].z = -1; //sets the Z component of the to "-1", used for not repeating pixels. Play commenting it. That's why some ellipses move a lot,
//they jump to another line of the image, at the other side
}
}
void setRandomPositions (PVector [] p) //p = "start" array
{
int i = 0;
while (i < p.length)
{
PVector pos = new PVector (random (width), random (height)); //gives random values in the lowest part of the screen
p [i] = pos;
i = i +1;
}
}
boolean isTarget (PVector p) //if true, it will be part of "randomPos" array. Darker pixels will be the target (darkness < 10)
{
int index = (int) p.y * newImg.width + (int) p.x; //Y component times the image width + X component (index of the image pixel, because size of the sketch = size of the image).
index = constrain (index, 0, newImg.pixels.length-1); //constrain? restringeix un valor entre un minim (0) i un maxim (pixels totals de la imatge, 512x424)
float bright = brightness (newImg.pixels[index]);
if (bright > 240) return false; //241 to 255, if white, FALSE
else if (bright < 10) return true; //0 to 9, if dark, TRUE
else
{
float rVal = random (0, bright); //10 to 240, rVal = random between 0 and (10 to 240)
if (rVal < 1) return true; // if no white and no dark, random (0,10) .. random (0,240) --> if < 1 then it will be target too
else return false; //10% prob (1/10) if its close to dark, 0.42% prob (1/240) if its close to white, so it goes close to dark
}
}
void keyPressed () //go to the initial state.
{
if (key == 's') {
saveFrame("picture-#####.jpg");
}
if(key == 'p') {
if (toggle == true) {
toggle=false;
} else
toggle=true;
}
}
