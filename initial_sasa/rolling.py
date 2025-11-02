import re
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path
from utils import extract_sasa_from_dat

data_dir = Path("./sasa_for_system_water")
sim_base_dir = Path("./OEP7/Simulations/integral")

sasa_data = {}

for i in range(1, 5):
    dat_file = data_dir / f"memb-{i}.dat"
    memb_dir = sim_base_dir / f"memb-{i}"
    
    frames, sasa = extract_sasa_from_dat(dat_file)
    
    # Get simulation time
    total_time_ns = get_sim_time_ns(memb_dir)
    
    if total_time_ns:
        time_per_frame_ns = total_time_ns / len(frames)
        time_axis_ns = np.arange(len(frames)) * time_per_frame_ns
        print(f"memb-{i}: {total_time_ns:.2f} ns total, {len(frames)} frames, {time_per_frame_ns:.4f} ns/frame")
    else:
        time_per_frame_ns = None
        time_axis_ns = frames  # fallback to frame numbers
        print(f"memb-{i}: Could not determine simulation time")
    
    sasa_data[f"memb-{i}"] = {
        'frames': frames,
        'time_ns': time_axis_ns,
        'sasa': sasa,
        'total_time_ns': total_time_ns,
        'time_per_frame_ns': time_per_frame_ns
    }

# # Calculate rolling average window for 5 ns
# # Use the average time per frame across all membranes
# avg_time_per_frame = np.mean([data['time_per_frame_ns'] for data in sasa_data.values() 
#                                if data['time_per_frame_ns'] is not None])
# window_5ns = int(5.0 / avg_time_per_frame)
# print(f"\nUsing rolling window of {window_5ns} frames for 5 ns average")

# # Apply rolling average
# for label in sasa_data:
#     sasa_data[label]['sasa_smooth'] = pd.Series(sasa_data[label]['sasa']).rolling(
#         window=window_5ns, center=True, min_periods=1
#     ).mean().values

for label in sasa_data:
    if sasa_data[label]['time_per_frame_ns'] is not None:
        window_5ns = int(5.0 / sasa_data[label]['time_per_frame_ns'])
        print(f"{label}: Using rolling window of {window_5ns} frames for 5 ns average")
    else:
        window_5ns = 50  # fallback
        print(f"{label}: Could not calculate window, using default of 50 frames")
    
    sasa_data[label]['sasa_smooth'] = pd.Series(sasa_data[label]['sasa']).rolling(
        window=window_5ns, center=True, min_periods=1
    ).mean().values


# # Plot original data with time on x-axis
# plt.figure(figsize=(18, 6))
# for label, data in sasa_data.items():
#     plt.plot(data['time_ns'], data['sasa'], label=label, alpha=0.3, linewidth=0.5)
#     plt.plot(data['time_ns'], data['sasa_smooth'], label=f"{label} (5ns avg)", alpha=0.9, linewidth=2)

# plt.xlabel('Time (ns)', fontsize=12)
# plt.ylabel('SASA (Ų)', fontsize=12)
# plt.title('LGWLAI Motif SASA over Time (with 5 ns rolling average)', fontsize=14)
# plt.legend()
# plt.grid(True, alpha=0.3)
# plt.tight_layout()
# plt.savefig(data_dir / 'sasa_plot_smoothed.png', dpi=300)
# print(f"\nPlot saved to {data_dir / 'sasa_plot_smoothed.png'}")

# # Stats with smoothed data
# f_stats = open(data_dir / 'stats_rolling.txt', 'w')
# f_stats.write("SASA Statistics (5 ns rolling average):\n")
# f_stats.write("="*50 + "\n\n")

# for label, data in sasa_data.items():
#     mean_orig = np.mean(data['sasa'])
#     std_orig = np.std(data['sasa'])
#     mean_smooth = np.mean(data['sasa_smooth'])
#     std_smooth = np.std(data['sasa_smooth'])
    
#     f_stats.write(f"{label}:\n")
#     f_stats.write(f"  Original: {mean_orig:.2f} ± {std_orig:.2f} Ų\n")
#     f_stats.write(f"  Smoothed: {mean_smooth:.2f} ± {std_smooth:.2f} Ų\n")
#     if data['total_time_ns']:
#         f_stats.write(f"  Simulation time: {data['total_time_ns']:.2f} ns\n")
#     f_stats.write("\n")

# f_stats.close()

# # Bar plot with smoothed data (reduced error bars)
# membranes = list(sasa_data.keys())
# means = [np.mean(sasa_data[membrane]['sasa_smooth']) for membrane in membranes]
# stds = [np.std(sasa_data[membrane]['sasa_smooth']) for membrane in membranes]

# plt.figure(figsize=(8, 6))
# plt.ylim(0,55)
# plt.bar(membranes, means, yerr=stds, capsize=5, alpha=0.7)
# plt.ylabel('Mean SASA (Ų)', fontsize=12)
# plt.title('Mean SASA Comparison (5 ns rolling average)', fontsize=14)
# plt.grid(True, alpha=0.3, axis='y')
# plt.savefig(data_dir / 'average_sasa_plot_smoothed.png', dpi=300)

# print("Analysis complete!")