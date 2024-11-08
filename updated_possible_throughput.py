import matplotlib.pyplot as plt

# Data points
x = [16384, 30000, 65536, 150000, 262144, 1048580, 4194300, 16777200, 67100890]
y = [200, 800, 1000, 3000, 5000, 10000, 29000, 29500, 29700]

# Plot
plt.figure(figsize=(10, 6))
plt.plot(x, y, marker='o', linestyle='-', color='b', label='FPGA Throughput')
plt.xlabel("Bytes per transfer")
plt.ylabel("Throughput")
plt.title("FPGA Throughput Plot")
plt.legend()
plt.grid(True)
plt.show()

