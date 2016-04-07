# fourcolors

An interactive, visual demonstration of the four color theorem.

Powered by [ProcessingJS](http://processingjs.org/).


## Algorithm idea

First, the user draws on the canvas. Once finished, the process could be as follows:

1. Find areas/nodes using BFS (fill() in MS Paint)
2. Find marginal points for each area
3. Check all nodes if they are neighbors using marginal points
4. Build inner graph representation (array?)
5. Solve graph (how?)
6. Display results on canvas or second "result"-canvas (which colors?)
