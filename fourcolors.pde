/*
Some code for drawing on a canvas and then color the whole thing.
Work in progress.
*/


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
ArrayList nodes = new ArrayList();
ArrayList edges = new ArrayList();
ArrayList marginal_points = new ArrayList();
ArrayList visible_edges = new ArrayList();

ArrayList lines = new ArrayList();
PVector start, end;
boolean dragging;
boolean stop_updating = false;
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
    if (solve_stage >= 0) solve();
    if (stop_updating) {
        // only update inner grid
        update_pixels();
    }
    else {
        background(255);
        //stroke(0, 0, 0);
        stroke(0);
        fill(255);
        rect(50, 50, grid_w-1, grid_h-1);

        // draw lines
        for (int i = 0; i < lines.size(); i++) {
            PVector a = lines.get(i)[0];
            PVector b = lines.get(i)[1];
            draw_line(a.x, a.y, b.x, b.y);
        }

        // draw temporary line while dragging
        if (dragging) draw_line(start.x, start.y, end.x, end.y);
    }
}

/* Draw a line with certain thickness.
An own implementation because line() is always smooth on HTML5 canvas.*/
void draw_point(int x, int y) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            int px = x-1+i;
            int py = y-1+j;
            if (px >= grid_margin && px < (grid_w + grid_margin)
            && py >= grid_margin && py < (grid_h + grid_margin))
                point(px, py);
        }
    }
}

/* Draws a line with the Bresenham line algorithm.
Adapted from http://stackoverflow.com/a/4672319/811708 */
void draw_line(int x0, int y0, int x1, int y1) {
    float dx = abs(x1-x0);
    float dy = Math.abs(y1-y0);
    float sx = (x0 < x1) ? 1 : -1;
    float sy = (y0 < y1) ? 1 : -1;
    float err = dx-dy;

    while(true){
        draw_point(x0, y0);
        if ((x0==x1) && (y0==y1)) break;
        float e2 = 2*err;
        if (e2 >-dy) { err -= dy; x0  += sx; }
        if (e2 < dx) { err += dx; y0  += sy; }
   }
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

void button_reset() {
    lines = new ArrayList();
    stop_updating = false;
    document.getElementById("data").innerHTML = '';
    document.getElementById("log").innerHTML = '';
}

void button_solve() {
    solve_stage = 0;
    stop_updating = true;
}

/* Main solving method.
The solving takes place in stages and logs its progress. */
void solve() {
    // TODO integrate solve_stage

    // TODO find marginal points

    // TODO find nodes

    // TODO find neighbors/edges

    // TODO solve graph

}

void update_pixels() {
    loadPixels();
    for (int y = 0; y < grid_h; y++) {
        for (int x = 0; x < grid_w; x++) {
            int dest = (grid_margin+y)*w + x+grid_margin;
            pixels[dest] = grid[y*grid_w + x];
        }
    }
    updatePixels();

    // TODO name nodes? display text?

    // visible edges
    stroke(pink);
    strokeWeight(4);
    for (int i = 0; i < visible_edges.size(); i++) {
        PVector[] pts = visible_edges.get(i);
        line(pts[0].x, pts[0].y, pts[1].x, pts[1].y);
    }

    stroke(black);
    strokeWeight(1);
}

/* Fill area with color c using BFS. */
void fill_area(x, y, c) {
    ArrayList queue = new ArrayList();
    queue.add(new PVector(x, y));

    while (queue.size() > 0) {
        // pop point from list and color it
        int last = queue.size() - 1;
        PVector p = queue.get(last);
        queue.remove(last);
        grid[p.y*grid_w + p.x] = c;

        // check neighbors
        if (check_color(p.x, p.y+1, white)) queue.add(new PVector(p.x, p.y+1));
        if (check_color(p.x, p.y-1, white)) queue.add(new PVector(p.x, p.y-1));
        if (check_color(p.x+1, p.y, white)) queue.add(new PVector(p.x+1, p.y));
        if (check_color(p.x-1, p.y, white)) queue.add(new PVector(p.x-1, p.y));
    }
}

boolean check_color(int x, int y, color col) {
    // border-safe color check
    if (x < 0 || y < 0 || x >= grid_w || y >= grid_h) { return false; }
    else if (grid[y*grid_w + x] == col) { return true; }
    else { return false; }
}


void button_generate_image() {
    img_data = document.getElementsByTagName("canvas")[0].toDataURL();
    document.getElementById("data").innerHTML = 'Generated image: <br> <img height="50" src="' + img_data + '">'
}
