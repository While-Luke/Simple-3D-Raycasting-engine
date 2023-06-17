import java.util.concurrent.*;

//Change the width and height of the window as well as the size of each pixel rendered
final int WIDTH = 800, HEIGHT = 800, PSIZE = 4; //higher values for PSIZE give better performance (must be a factor of width and height)
void settings(){size(WIDTH, HEIGHT, P2D);}
int FOV = 60;

color[] pcolors = new color[WIDTH*HEIGHT];

color background;

Object obj;

boolean mouseDragging = false;
PVector camPos = new PVector(0,0,-1);
PVector camAngle = new PVector(PI/2,PI/2);
PVector camDir = new PVector(0,0,1);

PVector qx;
PVector qy;
PVector p1m;


void setup(){
  background = color(#17B7FF);
  
  obj = new Object(parseObj("cube.obj", 0.5), color(230,230,230));
  
  println("Setup complete");
}

void draw(){
  loadBackground();
  
  if(keyPressed){
    switch(key){
      case 'w':
      camPos.add(new PVector(cos(camAngle.x), 0, sin(camAngle.x)).div(20));
      break;
      
      case 's':
      camPos.sub(new PVector(cos(camAngle.x), 0, sin(camAngle.x)).div(20));
      break;
      
      case 'a':
      camPos.sub(new PVector(sin(camAngle.x), 0, -cos(camAngle.x)).div(20));
      break;
      
      case 'd':
      camPos.add(new PVector(sin(camAngle.x), 0, -cos(camAngle.x)).div(20));
      break;
      
      case 'e':
      camPos.add(0,0.1,0);
      break;
      
      case 'q':
      camPos.add(0,-0.1,0);
      break;
      
      case 'p':
      renderImage();
      break;
    }
  }
  if(mouseDragging){
    float dx = PI*(mouseX - pmouseX)/180;
    float dy = PI*(mouseY - pmouseY)/180;
    float horiz = camAngle.x + dx*0.2;
    float vert = min(max(camAngle.y - dy*0.2, 0), PI);
    camAngle.set(horiz, vert);
  }
  
  //Precomputing for rays-----------------------------------------
  int m = HEIGHT/PSIZE; int k = WIDTH/PSIZE;
  PVector tn = sphereCoord(camAngle); //towards viewport
  PVector vn = sphereCoord(PVector.add(camAngle, new PVector(0, PI/2))); //vertical to viewport
  PVector bn = new PVector(); //horizontal to viewport
  PVector.cross(tn, vn, bn);
  
  float gx = tan(PI*FOV/360);
  float gy = gx*m/k;
  
  qx = PVector.mult(bn, 2*gx/k);
  qy = PVector.mult(vn, 2*gy/m);
  p1m = tn.sub(bn.mult(gx)).sub(vn.mult(gy));
  //--------------------------------------------------------------
  
  ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
  
  for(int j = 0; j < HEIGHT/PSIZE; j++){
    for(int i = 0; i < WIDTH/PSIZE; i++){
      quickthread thread = new quickthread(i, j);
      executor.execute(thread);
    }
  }
  executor.shutdown();
  try {
    executor.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS);
  } catch (InterruptedException e) {
  }
  
  render();
  println(frameRate); //<>//
}

void loadBackground(){
  for(int i = 0; i < pcolors.length; i++){
    pcolors[i] = background; 
  }
}

void render(){
  loadPixels();
  for(int i = 0; i < pcolors.length; i++){
    pixels[i] = pcolors[i]; 
  }
  updatePixels();
}

void mousePressed(){
  mouseDragging = true;
}

void mouseReleased(){
  mouseDragging = false;
}

//Converts 2D direction vector with theta and phi into a 3D direction vector with x,y,z
PVector sphereCoord(PVector inp){
  float x = sin(inp.y)*cos(inp.x);
  float y = cos(inp.y);
  float z = sin(inp.y)*sin(inp.x);
  PVector out = new PVector(x, y, z);
  return out;
}

//https://en.wikipedia.org/wiki/Ray_tracing_(graphics)#Calculate_rays_for_rectangular_viewport
PVector ray(int i, int j, PVector qx, PVector qy, PVector p1m){
  PVector qi = PVector.mult(qx, i);
  PVector qj = PVector.mult(qy, j);
  PVector pij = PVector.add(PVector.add(p1m, qi), qj);
  return pij;
}

class quickthread implements Runnable{
  int i;
  int j;
  
  quickthread(int i, int j){
    this.i = i;
    this.j = j;
  }
  
  void run(){
    camDir = ray(i, j, qx, qy, p1m);
    color c = obj.quickRenderObject(camPos, camDir);
    for(int x = 0; x < PSIZE; x++){
      for(int y = 0; y < PSIZE; y++){
        pcolors[(i*PSIZE)+x + ((j*PSIZE)+y) * WIDTH] = c;
      }
    }
  }
}

int iwidth = 1920, iheight = 1080; //width and height of the image rendered
PImage img; //image is unaffected by PSIZE, always has PSIZE of 1

PVector iqx;
PVector iqy;
PVector ip1m;
PVector icamPos;

void renderImage(){
  println("Beginning Render");
  img = createImage(iwidth, iheight, RGB);
  
  PVector icamAngle = camAngle;
  
  PVector itn = sphereCoord(icamAngle); //towards viewport
  PVector ivn = sphereCoord(PVector.add(icamAngle, new PVector(0, PI/2))); //vertical to viewport
  PVector ibn = new PVector(); //horizontal to viewport
  PVector.cross(itn, ivn, ibn);
  
  float igx = tan(PI*90/360);
  float igy = igx*iheight/iwidth;
  
  iqx = PVector.mult(ibn, 2*igx/iwidth);
  iqy = PVector.mult(ivn, 2*igy/iheight);
  ip1m = itn.sub(ibn.mult(igx)).sub(ivn.mult(igy));
  
  icamPos = camPos;
  img.loadPixels();
  
  ExecutorService executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
  
  for(int j = 0; j < iheight; j++){
    for(int i = 0; i < iwidth; i++){
      renderthread thread = new renderthread(i, j);
      executor.execute(thread);
    }
  }
  executor.shutdown();
  try {
    executor.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS);
  } catch (InterruptedException e) {
  }
  img.updatePixels();
  img.save("render.png");
  println("Render Finished");
}

class renderthread implements Runnable{
  int i;
  int j;
  
  renderthread(int i, int j){
    this.i = i;
    this.j = j;
  }
  
  void run(){
    PVector icamDir = ray(i, j, iqx, iqy, ip1m);
    img.pixels[i + j * iwidth] = obj.renderObject(icamPos, icamDir);
    if(i == 0 && j % (iheight/200) == 0){
      println(str(float(j)/float(iheight)*100) + "%");
    }
  }
}
