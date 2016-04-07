/* Some variables. */
int h = 300;
int w = 500;

color r = color(#E2041B);
color b = color(#048AD0);
color g = color(#338823);
color y = color(#FAEA04);

color[] colors = [r, b, g, y];
ArrayList lines = new ArrayList();
PVector start, end;
boolean dragging;

/* Setting up canvas. */
void setup() {
    size(w, h);
    frameRate(30);
}

/* Main draw loop */
void draw() {
    background(255);
    stroke(0);
    fill(255);
    // inner rectangle for drawing
    rect(50, 50, 400, 200);

    // draw lines
    for (int i = 0; i < lines.size(); i++) {
        PVector a = lines.get(i)[0];
        PVector b = lines.get(i)[1];
        line(a.x, a.y, b.x, b.y);
    }

    // draw temporary line while dragging
    if (dragging)
        line(start.x, start.y, end.x, end.y);
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
    // if mouse released, add line to "real" lines
    dragging = false;
    end = new PVector(mouseX, mouseY);
    lines.add([start, end]);
    start = new PVector(end.x, end.y);
}
