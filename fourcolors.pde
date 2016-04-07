/* Some general variables. */
int scale = 4;
int h = 300;
int w = 500;
int grid_h = 200;
int grid_w = 400;
int grid_margin = 50;
int[] grid = new int[grid_h*grid_w];

color black = color(#000000);
color white = color(#FFFFFF);
color purple = color(#800080);
color pink = color(#FF00FF);

color r = color(#E2041B);
color b = color(#048AD0);
color g = color(#338823);
color y = color(#FAEA04);

color[] colors = [r, b, g, y];

ArrayList lines = new ArrayList();
PVector start, end;
boolean dragging;
float solve_start;

/* Setting up canvas. */
void setup() {
    console.log("Starting up.");
    noSmooth();
    size(w, h);
    frameRate(30);
    dragging = false
    textSize(16);
    start = new PVector(w/2, h/2);
}

/* Main loop */
void draw() {
    background(255);
    stroke(0);
    fill(255);
    rect(50, 50, grid_w-1, grid_h-1);

    // draw lines
    for (int i = 0; i < lines.size(); i++) {
        PVector a = lines.get(i)[0];
        PVector b = lines.get(i)[1];
        line(a.x, a.y, b.x, b.y);
    }

        // draw temporary line while dragging
    if (dragging) line(start.x, start.y, end.x, end.y);
}

/* mouse input */
void mouseDragged() {
    end = new PVector(mouseX, mouseY);
    dragging = true;
}

void mousePressed() {
    start = new PVector(mouseX, mouseY);
}

void mouseReleased() {
    dragging = false;
    end = new PVector(mouseX, mouseY);
    lines.add([start, end]);
    start = new PVector(end.x, end.y); // build map by single clicks
}

/* Main solving method. */
void solve() {
    // TODO integrate solve_stage

    // TODO find nodes
    
    // TODO find marginal points

    // TODO find neighbors/edges

    // TODO build graph

    // TODO solve graph

}
