# fourcolors

An visual demonstration of the four color theorem / map solver, powered by [ProcessingJS](http://processingjs.org/).

![graph coloring](https://github.com/akleemans/fourcolors/blob/master/coloring.png)

The algorithm in action:

![graph coloring](https://github.com/akleemans/fourcolors/blob/master/coloring.gif)

See [Demo & Blog post](https://www.kleemans.ch/four-color-theorem-map-solver) for.

## How it works

First, the user draws on the canvas. Once finished, the process could be as follows:

1. Find areas/nodes using flood fill (BFS)
2. Find neighbors/edges using "marginal points" for each area and comparing distances
4. Build inner graph representation
5. Solve graph with Welsh-Powell and if this fails, try backtracking
6. Display results on canvas
