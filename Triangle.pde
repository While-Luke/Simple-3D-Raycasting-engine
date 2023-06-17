class Triangle{
  PVector h = new PVector();
  PVector s = new PVector();
  PVector q = new PVector();
  
  PVector vertex0;
  PVector vertex1;
  PVector vertex2;
  
  PVector edge1;
  PVector edge2;
  PVector normal;
  
  PVector center;
  float size;
  
  float[] transformation;
  
  Triangle(float x1, float y1, float z1, float x2, float y2, float z2, float x3, float y3, float z3){
    vertex0 = new PVector(x1, y1, z1);
    vertex1 = new PVector(x2, y2, z2);
    vertex2 = new PVector(x3, y3, z3);
    edge1 = new PVector();
    edge2 = new PVector();
    normal = new PVector();
    PVector.sub(vertex1, vertex0, edge1);
    PVector.sub(vertex2, vertex0, edge2);
    PVector.cross(edge1, edge2, normal);
    
    center = PVector.add(PVector.add(vertex0, vertex1), vertex2).div(3);
    size = max(center.dist(vertex0), center.dist(vertex1), center.dist(vertex2));
    
    compMat();
  }
  Triangle(PVector v1, PVector v2, PVector v3){
    vertex0 = v1;
    vertex1 = v2;
    vertex2 = v3;
    edge1 = new PVector();
    edge2 = new PVector();
    normal = new PVector();
    PVector.sub(vertex1, vertex0, edge1);
    PVector.sub(vertex2, vertex0, edge2);
    PVector.cross(edge1, edge2, normal);
    
    center = PVector.add(PVector.add(vertex0, vertex1), vertex2).div(3);
    size = max(center.dist(vertex0), center.dist(vertex1), center.dist(vertex2));
    
    compMat();
  }
  
  //Used only for Baldwin-Weber intersection
  void compMat(){
    transformation = new float[12];
    float x1, x2;
    float num = vertex0.dot(normal);
    
    if (abs(normal.x) > abs(normal.y) && abs(normal.x) > abs(normal.z)) {
        
        x1 = vertex1.y * vertex0.z - vertex1.z * vertex0.y;
        x2 = vertex2.y * vertex0.z - vertex2.z * vertex0.y;
        
        //Do matrix set up here for when a = 1, b = c = 0 formula

        transformation[0] = 0.0f;
        transformation[1] = edge2.z / normal.x;
        transformation[2] = -edge2.y / normal.x;
        transformation[3] = x2 / normal.x;
        
        transformation[4] = 0.0f;
        transformation[5] = -edge1.z / normal.x;
        transformation[6] = edge1.y / normal.x;
        transformation[7] = -x1 / normal.x;
        
        transformation[8] = 1.0f;
        transformation[9] = normal.y / normal.x;
        transformation[10] = normal.z / normal.x;
        transformation[11] = -num / normal.x;
    }
    else if (abs(normal.y) > abs(normal.z)) {
        
        x1 = vertex1.z * vertex0.x - vertex1.x * vertex0.z;
        x2 = vertex2.z * vertex0.x - vertex2.x * vertex0.z;
        
        // b = 1 case

        transformation[0] = -edge2.z / normal.y;
        transformation[1] = 0.0f;
        transformation[2] = edge2.x / normal.y;
        transformation[3] = x2 / normal.y;
        
        transformation[4] = edge1.z / normal.y;
        transformation[5] = 0.0f;
        transformation[6] = -edge1.x / normal.y;
        transformation[7] = -x1 / normal.y;
        
        transformation[8] = normal.x / normal.y;
        transformation[9] = 1.0f;
        transformation[10] = normal.z / normal.y;
        transformation[11] = -num / normal.y;
    }
    else if (abs(normal.z) > 0) {
        
        x1 = vertex1.x * vertex0.y - vertex1.y * vertex0.x;
        x2 = vertex2.x * vertex0.y - vertex2.y * vertex0.x;
        
        // c = 1 case

        transformation[0] = edge2.y / normal.z;
        transformation[1] = -edge2.x / normal.z;
        transformation[2] = 0.0f;
        transformation[3] = x2 / normal.z;
        
        transformation[4] = -edge1.y / normal.z;
        transformation[5] = edge1.x / normal.z;
        transformation[6] = 0.0f;
        transformation[7] = -x1 / normal.z;
        
        transformation[8] = normal.x / normal.z;
        transformation[9] = normal.y / normal.z;
        transformation[10] = 1.0f;
        transformation[11] = -num / normal.z;
    }
  }

  //Möller–Trumbore intersection algorithm
  //https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm#Java_implementation
  double _intersection(PVector rayOrigin, PVector rayDirection){
    float d = rayDirection.cross(PVector.sub(rayOrigin, center)).mag(); //closest point from ray to center
    if(d > size) return -1;
    
    double a, u, v;
    PVector.cross(rayDirection, edge2, h);
    a = edge1.dot(h);
    
    if (a > -EPSILON && a < EPSILON) {
        return -1;    // This ray is parallel to this triangle.
    }
  
    PVector.sub(rayOrigin, vertex0, s);
    u = s.dot(h)/a;
  
    if (u < 0.0 || u > 1.0) {
        return -1;
    }
  
    PVector.cross(s, edge1, q);
    v = rayDirection.dot(q)/a;
  
    if (v < 0.0 || u + v > 1.0) {
        return -1;
    }
  
    // At this stage we can compute t to find out where the intersection point is on the line.
    double t = edge2.dot(q)/a;
    if (t > EPSILON) { // ray intersection
        return t;
    } // This means that there is a line intersection but not a ray intersection.
    return -1;
  }
  
  //Baldwin-Weber ray-triangle intersection algorithm
  //https://jcgt.org/published/0005/03/03/
  double intersection(PVector rayOrigin, PVector rayDirection){
    // Get barycentric z components of ray origin and direction for calculation of t value
    float transS = transformation[8] * rayOrigin.x + transformation[9] * rayOrigin.y + transformation[10] * rayOrigin.z + transformation[11];
    float transD = transformation[8] * rayDirection.x + transformation[9] * rayDirection.y + transformation[10] * rayDirection.z;
    
    float ta = -transS / transD;
    
    // Reject negative t values
    if (ta < 0) return -1;
    
    // Get global coordinates of ray's intersection with triangle's plane.
    float[] wr = new float[]{rayOrigin.x + ta * rayDirection.x, rayOrigin.y + ta * rayDirection.y, rayOrigin.z + ta * rayDirection.z};

    // Calculate "x" and "y" barycentric coordinates
    float xg = transformation[0] * wr[0] + transformation[1] * wr[1] + transformation[2] * wr[2] + transformation[3];
    float yg = transformation[4] * wr[0] + transformation[5] * wr[1] + transformation[6] * wr[2] + transformation[7];
    
    // final intersection test
    if (xg >= 0.0f && yg >= 0.0f && yg + xg < 1.0f) {
      return ta;
    }
    return -1;
  }
  
  PVector reflect(PVector dir){
    PVector na = normal.copy();
    na.normalize();
    return PVector.sub(dir, PVector.mult(na, 2*dir.dot(na)));
  }
}
