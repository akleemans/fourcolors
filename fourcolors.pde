/* Some variables. */
int h = 300;
int w = 500;

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
}
