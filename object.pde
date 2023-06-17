PVector lightSource = new PVector(0.5,1,0);

class Object{
  Triangle[] mesh;
  color c;
  
  Object(Triangle[] m, color c){
    mesh = m;
    this.c = c;
  }
  Object(Triangle[] m){
    mesh = m;
    c = color(10);
  }
  
  //render object with basic lighting
  color renderObject(PVector rayOrigin, PVector rayDirection){
    double d;
    double minDepth = Double.MAX_VALUE;
    Triangle saving = mesh[0];
    for(Triangle t : mesh){
      d = t.intersection(rayOrigin, rayDirection);
      if(d > 0 && d < minDepth) {
        minDepth = d;
        saving = t;
      }
    }
    if(minDepth == Double.MAX_VALUE) return background;
    float a = PVector.angleBetween(saving.normal, lightSource);
    return lerpColor(color(0, 0, 0), c, 1-(a/PI));
  }
  
  //render object without calculating light
  color quickRenderObject(PVector rayOrigin, PVector rayDirection){
    for(Triangle t : mesh){
      if(t.intersection(rayOrigin, rayDirection) > 0) return c;
    }
    return background;
  }
}
