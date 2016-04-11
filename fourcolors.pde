/*
Some code for drawing on a canvas and then color the whole thing.
Work in progress.

Pure gold: http://processingjs.org/reference/
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
color green = color(#00FF00);
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
int solve_stage = -1;

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
    nodes.clear();
    edges.clear();
    visible_edges.clear();
    marginal_points.clear();
}

void button_solve() {
    solve_start = millis();
    solve_stage = 0;
    stop_updating = true;
}

/* Main solving method.
The solving takes place in stages and logs its progress. */
void solve() {
    if (solve_stage == 0) {
        update_status("Loading pixels...");
        // get pixel grid, w x h = 400 x 200
        loadPixels();
        for (int y = 0; y < grid_h; y++) {
            for (int x = 0; x < grid_w; x++) {
                int src = (grid_margin+y)*w + x+grid_margin;
                grid[y*grid_w + x] = pixels[src];
            }
        }
        solve_stage++;
    }
    else if (solve_stage == 1 && check_time()) { solve_stage++; }
    else if (solve_stage == 2) {
        update_status("Analyzing areas & finding nodes...");
        find_nodes();
        update_pixels();
        update_status("Found a total of " + nodes.size() + " areas/nodes.");
        solve_stage++;
    }
    else if (solve_stage == 3 && check_time()) { solve_stage++; }
    else if (solve_stage == 4) {
        update_status("Analyzing neighbors & finding edges...");
        // TODO generate graph pt. 2: find edges
        find_edges();
        update_status("Found a total of " + edges.size() + " edges.");
        solve_stage++;
    }
    else if (solve_stage == 5 && check_time()) { solve_stage++; }
    else if (solve_stage == 6) {
        update_status("Building graph...");
        // TODO build graph

        solve_stage++;
    }
    else if (solve_stage == 7 && check_time()) { solve_stage++; }
    else if (solve_stage == 8) {
        update_status("Solving graph, stand by");
        // TODO solving graph

        solve_stage++;
    }
    else if (solve_stage == 9 && check_time()) { solve_stage++; }
    else if (solve_stage == 10) {
        update_status("Coloring graph accordingly...");
        // TODO color graph
        update_pixels();
        solve_stage++;
    }
    else if (solve_stage == 11 && check_time()) { solve_stage++; }
    else if (solve_stage == 12) {
        update_status("Finished!");
        update_pixels();
        solve_stage++;
    }
}

boolean check_time() {
    return (solve_start + solve_stage*1000) < millis();
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

    // marginal points
    stroke(pink);
    strokeWeight(2);
    int m = grid_margin;
    for (int i = 0; i < marginal_points.size(); i++) {
        ArrayList node = marginal_points.get(i);
        for (int j = 0; j < node.size(); j++) {
            PVector p = node.get(j);
            point(p.x + m, p.y + m);
        }
    }

    // visible edges
    stroke(green);
    strokeWeight(4);
    for (int i = 0; i < visible_edges.size(); i++) {
        PVector[] pts = visible_edges.get(i);
        line(pts[0].x+m, pts[0].y+m, pts[1].x+m, pts[1].y+m);
    }

    stroke(black);
    strokeWeight(1);
}

void update_status(String s) {
    document.getElementById("log").innerHTML += '<br>' + s;
    console.log(s);
}

/* Loop through pixels.
If a white one was found, trigger BFS fill_area().*/
void find_nodes() {
    for (int y = 0; y < grid_h; y++) {
        for (int x = 0; x < grid_w; x++) {
            if (grid[grid_w*y + x] == white) {
                color col;
                // color is our node key, avoid collisions
                do { col = random_color(); } while (nodes.contains(col));
                nodes.add(col);
                fill_area(x, y, col);
            }
        }
    }
}

/* Rand-pixel pro node identifizieren, um diese mit anderen nodes zu vergleichen*/
void find_edges() {
    // find marginal points from all nodes
    for (int i = 0; i < nodes.size(); i++) {
        color c = nodes.get(i);
        marginal_points.add(find_marginal_points(c));
    }

    // compare and check if nodes have an edge
    for (int i = 0; i < nodes.size(); i++) {
        for (int j = i+1; j < nodes.size(); j++) {
            boolean exit_flag = false;
            ArrayList a = marginal_points.get(i);
            ArrayList b = marginal_points.get(j);

            // check marginal points for distance
            for (int k = 0; k < a.size(); k++) {
                if (exit_flag) break;
                for (int l = 0; l < b.size(); l++) {
                    PVector p0 = a.get(k);
                    PVector p1 = b.get(l);
                    // TODO fine-tune this distance accordingly
                    if (dist(p0.x, p0.y, p1.x, p1.y) < 5) {
                        // edge between nodes i and j found
                        console.log("Edge found between " + i + " / " + j);
                        visible_edges.add([new PVector(p0.x, p0.y), new PVector(p1.x, p1.y)]);
                        edges.add([i, j])
                        exit_flag =  true;
                        break;
                    }
                }
            }
        }
    }
}

ArrayList find_marginal_points(color c) {
    ArrayList points = new ArrayList();

    // check neighbors of point, if point touches black its marginal
    for (int y = 0; y < grid_h; y++) {
        for (int x = 0; x < grid_w; x++) {
            if (grid[grid_w*y + x] == c) {
                // TODO also check diagonal points?
                if (check_color(x+1, y, black)) {points.add(new PVector(x, y));}
                else if (check_color(x-1, y, black)) {points.add(new PVector(x, y));}
                else if (check_color(x, y+1, black)) {points.add(new PVector(x, y));}
                else if (check_color(x, y-1, black)) {points.add(new PVector(x, y));}
            }
        }
    }
    console.log("Color " + c + " has " + points.size() + " marginal points.");
    return points;
}

color random_color() {
    //return randomColor({luminosity: 'bright'});
    return color(random(255), random(255), random(255));
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
