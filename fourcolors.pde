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
ArrayList node_mapping = new ArrayList();
int[] color_map;

ArrayList lines = new ArrayList();
PVector start, end;
boolean dragging;
boolean stop_updating = false;
boolean image_loaded = false;
float solve_start;
int solve_stage = -1;

/* Setting up canvas. */
void setup() {
    update_status("Starting up.");
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
    image_loaded = false;
    document.getElementById("data").innerHTML = '';
    document.getElementById("log").innerHTML = '';
    nodes.clear();
    edges.clear();
    visible_edges.clear();
    marginal_points.clear();
    node_mapping.clear();
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
        image_loaded = false;
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
        update_status("Analyzing marginal points & finding edges...");
        find_edges();
        update_pixels();
        update_status("Found a total of " + edges.size() + " edges.");
        solve_stage++;
    }
    else if (solve_stage == 5 && check_time()) { solve_stage++; }
    else if (solve_stage == 6) {
        update_status("Building & solving graph, stand by...");
        solve_graph();
        update_status("Finished.");
        update_pixels();
        solve_stage++;
    }
}

void solve_graph() {
    // for each node, calculate valence (nr of connected edges)
    update_status("Calculating valence...");
    int[] valence = new int[nodes.size()];
    int max_valence = 0;
    for (int i = 0; i < nodes.size(); i++) {
        for (int j = 0; j < edges.size(); j++) {
            int[] e = edges.get(j);
            if (e[0] == i || e[1] == i) {
                valence[i] += 1;
            }
        }
        if (max_valence < valence[i])
            max_valence = valence[i];
    }

    // sort by valence (bucket sort)
    int v = max_valence;
    ArrayList sorted_nodes = new ArrayList();
    ArrayList node_map = new ArrayList();
    int[] node_lookup = new int[nodes.size()]; // node_lookup[alter node] ergibt neuen node
    while (v > 0) { //sorted_nodes.size() < nodes.size()
        for (int i = 0; i < nodes.size(); i++) {
            if (valence[i] == v) {
                if (sorted_nodes.size() == 0) update_status("Node " + i + " has highest valence: " + v);
                sorted_nodes.add(nodes.get(i));
                node_map.add(i);
                node_lookup[i] = sorted_nodes.size()-1;
            }
        }
        v -= 1;
    }

    // update edges to correspond to newly sorted nodes
    ArrayList nodes_backup = nodes;
    ArrayList edges_backup = edges;

    nodes = sorted_nodes;
    ArrayList sorted_edges = new ArrayList();
    for (int i = 0; i < edges.size(); i++) {
        int[] e = edges.get(i);
        sorted_edges.add([ node_lookup[e[0]], node_lookup[e[1]] ]);
    }
    edges = sorted_edges;

    // begin coloring using Welsh-Powell algorithm
    // http://mrsleblancsmath.pbworks.com/w/file/fetch/46119304/vertex%20coloring%20algorithm.pdf
    color_map = new int[nodes.size()];
    for (int i = 0; i < nodes.size(); i++) { color_map[i] = -1; }
    for (int c = 0; c < 4; c++) {
        int col = colors[c];
        // color all nodes, not connected
        for (int i = 0; i < nodes.size(); i++) {
            // only check further if not already colored
            if (color_map[i] == -1) {
                coloring_possible = true;
                // check if coloring is possible
                for (int j = 0; j < i; j++) {
                    if (color_map[j] == c && have_edge(i, j)) {
                        coloring_possible = false;
                        break;
                    }
                }
                if (coloring_possible) {
                    node_mapping.add([nodes.get(i), col]);
                    color_map[i] = c;
                }
            }
        }
    }

    if (node_mapping.size() < nodes.size()) {
        update_status("Welsh-Powell not successful, could only color " + node_mapping.size() + " out of " + nodes.size() + ". Trying backtracking...");
    }
    else {
        update_status("Coloring successful with Welsh-Powell algorithm!");
        return;
    }

    // ===== brute-force with backtracking ====
    // resetting color_map
    for (int i = 0; i < nodes.size(); i++) { color_map[i] = -1; }
    edges = edges_backup;
    nodes = nodes_backup;

    // profiling
    int[] level = new int[nodes.size()];
    for (int i = 0; i < nodes.size(); i++) { level[i] = 0; }

    // add map with initial node and red
    node_mapping.clear();
    color_map[0] = 0;
    int i = 1;
    float start = millis();

    // algorithm ends when last element is set
    while (i < nodes.size()) {
        level[i] += 1;
        // time check
        if (millis() - start > 10*1000) { break; }
        //if (i>1) console.log("i =" + i + ", surrounding colors: " + color_map[i-1] + " " + color_map[i] + " " + color_map[i+1]);

        // assign color, starting from lowest color allowed
        boolean succesful = false;
        for (int c = color_map[i]+1; c < 4; c++) {
            console.log("Trying color "+ c);
            if (!color_connected(i, c)) {
                color_map[i] = c;
                // reset all following colors
                for (int j = i + 1; j < nodes.size(); j++) {
                    color_map[j] = -1;
                }
                succesful = true;
                break;
            }
        }

        // if no color found, go back
        if (color_map[i] == -1 || !succesful) { i -= 1; }
        else { i += 1; }
    }

    for (int i = 0; i < nodes.size(); i++) {
        console.log("level "+i+":" + level[i]);
    }

    // check if solution found in time
    int missing = 0;
    for (int i = 0; i < nodes.size(); i++) {
        if (color_map[i] == -1 ) { missing += 1; }
        else { node_mapping.add([nodes.get(i), colors[color_map[i]]]); }
    }
    if (missing > 0) { update_status("No solution found in time."); }
    else { update_status("Solution found with backtracking!"); }
}

boolean color_connected(int n, int c) {
    // check edges to other nodes and check their colors consulting color_map
    for (int i = 0; i < edges.size(); i++) {
        int[] e = edges.get(i);
        if ( (n == e[0] && color_map[e[1]] == c) || (n == e[1] && color_map[e[0]] == c) ) {
            return true;
        }
    }
    return false;
}

boolean have_edge(int n0, int n1) {
    // check if nodes have an edge
    for (int i = 0; i < edges.size(); i++) {
        int[] e = edges.get(i);
        if ( (e[0] == n0 && e[1] == n1) ||
             (e[0] == n1 && e[1] == n0) ) {
            return true;
        }
    }
    // no edge found until now
    return false;
}

boolean check_time() {
    return (solve_start + solve_stage*500) < millis();
}

void update_pixels() {
    if (!image_loaded) {
        loadPixels();
        for (int y = 0; y < grid_h; y++) {
            for (int x = 0; x < grid_w; x++) {
                int dest = (grid_margin+y)*w + x+grid_margin;
                pixels[dest] = grid[y*grid_w + x];
            }
        }
        updatePixels();
    }

    // TODO name nodes? display text?

    // marginal points
    if (node_mapping.size() > 0) {
        for (int y = 0; y < grid_h; y++) {
            for (int x = 0; x < grid_w; x++) {
                color c = grid[y*grid_w + x];
                for (int i = 0; i < node_mapping.size(); i++) {
                    int[] m = node_mapping.get(i);
                    if (c == m[0]) {
                        grid[y*grid_w + x] = m[1];
                    }
                }
            }
        }
    }
    else {
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
                do { col = random_color(); } while (nodes.contains(col) && col != black);

                // if fill_area return a new area, verify node
                if (fill_area(x, y, col)) nodes.add(col);
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
    update_status("Found marginal points for all areas.");

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
    //update_status("Color " + c + " has " + points.size() + " marginal points.");
    return points;
}

color random_color() {
    //return randomColor({luminosity: 'bright'});
    return color(random(255), random(255), random(255));
}

/* Fill area with color c using BFS. */
void fill_area(x, y, c) {
    int n = 0;
    ArrayList queue = new ArrayList();
    queue.add(new PVector(x, y));

    while (queue.size() > 0) {
        // pop point from list and color it
        int last = queue.size() - 1;
        PVector p = queue.get(last);
        queue.remove(last);
        grid[p.y*grid_w + p.x] = c;
        n += 1;

        // check neighbors
        if (check_color(p.x, p.y+1, white)) queue.add(new PVector(p.x, p.y+1));
        if (check_color(p.x, p.y-1, white)) queue.add(new PVector(p.x, p.y-1));
        if (check_color(p.x+1, p.y, white)) queue.add(new PVector(p.x+1, p.y));
        if (check_color(p.x-1, p.y, white)) queue.add(new PVector(p.x-1, p.y));
    }
    // one-pixel bug: if only one pixel, don't count it as separate area
    if (n == 1) {
        grid[y*grid_w + x] = black;
        return false;
    }
    else { return true; }
}

boolean check_color(int x, int y, color col) {
    // border-safe color check
    if (x < 0 || y < 0 || x >= grid_w || y >= grid_h) { return false; }
    else if (grid[y*grid_w + x] == col) { return true; }
    else { return false; }
}


void button_generate_image() {
    img_data = document.getElementsByTagName("canvas")[0].toDataURL();
    if (document.getElementById("data").innerHTML == '') {
        document.getElementById("data").innerHTML = 'Snapshots: <br> <img height="50" src="' + img_data + '">'
    }
    else {
        document.getElementById("data").innerHTML += '<img height="50" src="' + img_data + '">'
    }
}

void button_load_image(s) {
    canvas = document.getElementsByTagName("canvas")[0];
    context = canvas.getContext('2d');
    img = new Image();
    stop_updating = true;
    image_loaded = true;
    img.onload = function() {
        context.drawImage(this, 0, 0, canvas.width, canvas.height);
    }
    img.src = s;
}
