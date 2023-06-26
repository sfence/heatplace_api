
import lupa
import matplotlib.pyplot as plot
import math
import os

dirpath = os.path.dirname(os.path.realpath(__file__))

lua = lupa.LuaRuntime(unpack_returned_tuples=True)

output = lua.eval("dofile(\"{}/tb_fireplace.lua\")".format(dirpath))

output = dict(output)
for graph_name in output.keys():
  graph = dict(output[graph_name])
  for key in graph.keys():
    values = dict(graph[key])
    size = len(values)

    print(size)

    axis_x = [0]*size
    axis_y = [0]*size
    
    start_offset = min(values.keys())
    for x in range(size):
      axis_x[x] = x
      axis_y[x] = values[x+start_offset]

    plot.plot(axis_x, axis_y, label=key)

  plot.title(graph_name)
  plot.legend()
  plot.show()

