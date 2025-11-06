max_iterations = 300
iterations = range(1, max_iterations+1)

w_avg_v2 = (1/max_iterations) * sum([0.998**(i-1) for i in iterations])
print(f"pso v2 w avg: {w_avg_v2}")

w_avg_v3 = (1/max_iterations) * sum([0.95 - (0.95 - 0.55)*((i-1)/(max_iterations-1)) for i in iterations])
print(f"pso v3 w avg: {w_avg_v3}")

w_avg_v4 = (1/max_iterations) * sum([0.95 - (0.95 - 0.35)*(((i-1)/(max_iterations-1))**2) for i in iterations])
print(f"pso v4 w avg: {w_avg_v4}")