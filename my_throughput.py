import matplotlib.pyplot as plt

# Data from your summary results
sizes = [
    16384, 32768, 65536, 131072, 
    262144, 524288, 1048576, 
    2097152, 4194304, 8388608, 
    16777216, 33554432
]
throughput = [
    378.316, 827.605, 901.955, 
    1126.45, 1076.83, 1283.95, 
    1241.94, 1413.68, 1416.98, 
    1486.44, 1345.79, 1312.78
]

# Create a figure and axis
plt.figure(figsize=(10, 6))

# Plotting the throughput
plt.plot(sizes, throughput, marker='o', linestyle='-', color='b', label='Throughput (MBits/s)')

# Setting the title and labels
plt.title('FPGA Throughput vs Bytes per transfer', fontsize=14)
plt.xlabel('Bytes per transfer', fontsize=12)  # Changed label to Buffer Size (Bytes)
plt.ylabel('Throughput (MBits/s)', fontsize=12)
plt.xticks(sizes, rotation=45)  # Set x-ticks to be the buffer sizes
plt.grid()

# Add a legend
plt.legend()

# Show the plot
plt.tight_layout()
plt.show()
