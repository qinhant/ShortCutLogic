import matplotlib.pyplot as plt

plt.rcParams.update({'font.size': 10})

# Example data for 8 bars
labels = ['Multiplier', 'Modexp', 'GCD', 'FP_ADD', 'SecEnclave', 'Cache', 'Sodor', 'Rocket']
values = [27.0, 1.8, 8.9, 5.6, 49.3, 32.3, 4.2, 2.3]

# Create the bar chart
fig, ax = plt.subplots(figsize=(8, 5))
bars = ax.bar(labels, values, color='white', edgecolor='black')

# Add value labels on top of each bar
ax.bar_label(bars, padding=3)

# Add labels and title
ax.set_xlabel('Design')
ax.set_ylabel('Speedup')
# plt.title('Example Bar Graph with 8 Bars')
# plt.grid(axis='y', linestyle='--', alpha=0.7)

# Adjust layout
plt.tight_layout()

# Save as PDF
plt.savefig("output/speedup.pdf")