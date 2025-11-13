max_iterations = 300
iterations = range(1, max_iterations+1)

w_avg_v2 = (1/max_iterations) * sum([0.96**(i-1) for i in iterations])
print(f"pso-k v4 w avg: {w_avg_v2}")