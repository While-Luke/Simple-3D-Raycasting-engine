
//Read data in from .obj file and return array of Triangles to be turned into an Object object
Triangle[] parseObj(String filename, float scale){
  BufferedReader reader = createReader(filename);
  String line;
  ArrayList<PVector> vertices = new ArrayList();
  ArrayList<Triangle> mesh = new ArrayList();
  
  try{
    while((line = reader.readLine()) != null){
      String[] spl = line.split("\\s+");
      
      if(spl.length == 0 || spl[0].equals("#")) continue;
      
      if(spl[0].equals("v")){
        PVector vertex = new PVector(float(spl[1])*scale, float(spl[2])*scale, float(spl[3])*scale);
        vertices.add(vertex);
      }
      if(spl[0].equals("f")){
        for(int i = 0; i < spl.length-3; i++){
          PVector v1 = vertices.get(int(split(spl[1], '/')[0])-1);
          PVector v2 = vertices.get(int(split(spl[2+i], '/')[0])-1);
          PVector v3 = vertices.get(int(split(spl[3+i], '/')[0])-1);
          mesh.add(new Triangle(v1, v2, v3));
        }
      }
    }
    Triangle[] ma = new Triangle[mesh.size()];
    ma = mesh.toArray(ma);
    return ma;
  }
  catch(IOException e){
    println("Error while reading file: " + filename);
    println(e);
    e.printStackTrace();
    exit();
    return null;
  }
}
