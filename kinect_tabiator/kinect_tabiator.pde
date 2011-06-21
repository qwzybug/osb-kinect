/*

NOTE:
Relies on devin.skel in data folder for this sketch
http://doormouse.org/misc/devin.skel

*/

import SimpleOpenNI.*;

SimpleOpenNI  kinect;

boolean judging = false;
boolean devinMode = false;

boolean debug = true;
boolean showGladiator = true;

// no enums in processing...
// public enum HandPosition { NONE, LOW, MID, HIGH }
public static final int HAND_NONE = 0;
public static final int HAND_LOW  = 1;
public static final int HAND_MID  = 2;
public static final int HAND_HIGH = 3;

void setup() {
  
   kinect = new SimpleOpenNI(this);
   kinect.enableDepth();

   kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  
  
     size(640, 480);
  
    background(200,0,0);

  stroke(0,0,255);
  strokeWeight(3);
  smooth();

  if (debug) {
    PFont font = loadFont("Menlo-Bold-48.vlw"); 
    textFont(font);
  }

}

void draw(){
  kinect.update();
  
  image(kinect.depthImage(), 0,0);
  
  IntVector userList = new IntVector();
    kinect.getUsers(userList);
  
  if (userList.size() < 1)
    return;
  
  int user = userList.get(0);
  if (kinect.isTrackingSkeleton(user))
    drawSkeleton(user);
  else
    return;
  
  float zThreshold = 500;    // minimum hand distance
  float midThreshold = 150;   // width of the vertical plane
  float moveThreshold = 250;
  
  float rightHandDistance = 1000;
  float handsZDistance = -1;

  PVector neck = new PVector();
  kinect.getJointPositionSkeleton(user, SimpleOpenNI.SKEL_NECK, neck);

  // ...actually the right hand...
  PVector leftHand = new PVector();
  kinect.getJointPositionSkeleton(user, SimpleOpenNI.SKEL_LEFT_HAND, leftHand);

  // check if the hand is far enough away
  float zDistance = neck.z - leftHand.z;
  if (debug)
    text(round(zDistance), 5, 424);
  
  if (zDistance < zThreshold)
    return;
  
  // check the height of the hand
  float yDistance = leftHand.y - neck.y;
  int pos = HAND_NONE;
  
  if (yDistance < -moveThreshold)
    pos = HAND_LOW;
  else if (yDistance > -midThreshold && yDistance < midThreshold)
    pos = HAND_MID;
  else if (yDistance > moveThreshold)
    pos = HAND_HIGH;
  
  if (judging) {
    if (pos == HAND_LOW)
      doKill();
    else if (pos == HAND_HIGH)
      doSpare();
  }
  else if (pos == HAND_MID)
    startJudging();

  if (debug) {
    text(round(yDistance), 5, 64);
    switch (pos) {
      case HAND_LOW: text("LOW", 5, 128); break;
      case HAND_MID: text("MID", 5, 128); break;
      case HAND_HIGH: text("HIGH", 5, 128); break;
    }
  }
}

void runShell(String sh) {
  try{
    Runtime.getRuntime().exec(sh);
  } catch (IOException ex) {
     println(ex.toString());
  }
}

void doAppleScript(String scr) {
  try {
    Runtime runtime = Runtime.getRuntime();
    String[] args = { "osascript", "-e", scr };
    runtime.exec(args);
  } catch (IOException ex) {
    println(ex.toString());
  }
}

void startJudging() {
  doAppleScript("tell application \"Safari\" to activate");
  if (showGladiator)
    runShell("/usr/bin/open /Users/d/Desktop/suspense.mp4");
  judging = true;
}

void doKill() {
  doAppleScript("tell application \"Safari\" to activate");
  doAppleScript("tell application \"Safari\" to close current tab of front window");
  if (showGladiator)
    runShell("/usr/bin/killall VLC");
  judging = false;
}

void doSpare () {
  doAppleScript("tell application \"Safari\" to activate");
  doAppleScript("tell application \"System Events\" to tell process \"Safari\" to click menu item \"Select Next Tab\" of menu \"Window\" of menu bar 1");
  if (showGladiator)
    runShell("/usr/bin/killall VLC");
  judging = false;
}

void keyPressed(){
  if (key == 'l') {
    // load Devin calibration file
    IntVector userList = new IntVector();
    kinect.getUsers(userList);
    if(userList.size() < 1)
    {
      println("You need at least one active user!");
      return;
    }
    
    int user = userList.get(0);
    
    if(kinect.loadCalibrationDataSkeleton(user, "devin.skel"))
    {
      kinect.startTrackingSkeleton(user);
      devinMode = true;
      println("Loaded calibration from file.");
    }
    else
      println("Can't load calibration file.");
  }
  if (key == 'r') {
    // reset
    devinMode = false;
    judging = false;
  }
}


/*
 ***************
 * Kinect events
 ***************
 */

void onNewUser(int userId)
{
  println("New user: " + userId);
  
  if (!devinMode)
    kinect.startPoseDetection("Psi",userId);
}

void onLostUser(int userId)
{
  println("Lost user " + userId);
}

void onStartCalibration(int userId)
{
  println("Started calibration for user " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
  println("End calibration for user " + userId + ", successfull: " + successfull);
  
  if (successfull) 
  { 
    println("  User calibrated !!!");
    kinect.startTrackingSkeleton(userId); 
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
    println("  Start pose detection");
    kinect.startPoseDetection("Psi",userId);
  }
}

void onStartPose(String pose,int userId)
{
  if (devinMode)
    return;
  
  println("Started pose for user " + userId + ", pose: " + pose);
  
  kinect.stopPoseDetection(userId); 
  kinect.requestCalibrationSkeleton(userId, true);
}

void onEndPose(String pose,int userId)
{
  println("End pose for user " + userId + ", pose: " + pose);
}

// debug

void drawSkeleton(int userId)
{
  // to get the 3d joint data
  /*
  PVector jointPos = new PVector();
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,jointPos);
  println(jointPos);
  */
  
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}

