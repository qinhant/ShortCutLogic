import matplotlib.pyplot as plt

plt.rcParams.update({'font.size': 10})



labels = ['Multiplier', 'Modexp', 'GCD', 'FP_ADD', 'SecEnclave', 'Cache', 'Sodor', 'Rocket']
values = [27.0, 1.8, 8.9, 5.6, 49.3, 32.3, 4.2, 2.3]

fig, ax = plt.subplots(figsize=(8, 3))
bars = ax.bar(labels, values, color='lightblue', edgecolor='lightblue')
ax.bar_label(bars, padding=3)              # labels just above bars

ax.set_xlabel('Design')
ax.set_ylabel('Speedup')
ax.set_ylim(0, max(values) * 1.12)         # 12% headroom so 49.3 fits
# or: ax.margins(y=0.1)  # ~10% headroom

plt.tight_layout()
plt.savefig("output/speedup.pdf")