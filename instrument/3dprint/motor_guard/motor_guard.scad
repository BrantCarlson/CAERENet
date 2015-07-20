difference(){
  union(){
    difference(){
      union(){cylinder(r=32+0.8,h=45); cylinder(r1=34.8,r2=32.8,h=3);}
      translate([0,0,3])cylinder(r=32,h=48);
      translate([0,0,-0.1])cylinder(r1=30,r2=32,h=3.2);
    }
    difference(){cylinder(r=36.8,h=0.8); translate([0,0,-1])cylinder(r=28,h=48);}
  }
  translate([0,0,-10]) cube([50,50,100]);
  rotate([0,0,30]) translate([0,0,-10]) cube([50,50,100]);
  for(i = [25 : 215/8 : 215]){
    rotate([0,0,-i]) translate([0,-5,0.8]) cube([100,10,12]);
    rotate([0,0,-i]) translate([0,-5,0.8+14]) cube([100,10,14]);
    rotate([0,0,-i]) translate([0,-5,0.8+30]) cube([100,10,12]);
  }
}

