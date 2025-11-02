import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
from utils import get_sim_time_ns  # keep this in utils.py
import pandas as pd

# -------- USER OPTIONS --------
DATA_DIR = Path("./test")
NPZ_FILE = DATA_DIR / "motif_sasa.npz"
BASE_SIM_DIR = Path("../.OEP7/Simulations/integral")  # where memb-x dirs are
TRUNCATE = True         # True = trim all sims to shortest
X_AXIS = "time"         # "frames" or "time"
SMOOTH_NS = 0.0  # set to 0 to disable smoothing; window in nanoseconds
# --------------------------------

def load_sasa_data(npz_file: Path, truncate: bool = True):
    data = np.load(npz_file)
    sasa_dict = {key: data[key] for key in data.files}
    
    min_len = min(len(arr) for arr in sasa_dict.values())
    processed = {}
    
    for key, arr in sasa_dict.items():
        if truncate:
            arr = arr[:min_len]
            frames = np.arange(min_len)
        else:
            frames = np.arange(len(arr))
        
        processed[key] = {"frames": frames, "sasa": arr}
    
    return processed, min_len


def smooth_by_ns(sasa, time_per_frame_ns, smooth_ns):
    """Return smoothed SASA using a rolling window defined in ns."""
    if smooth_ns <= 0 or time_per_frame_ns is None:
        return sasa  # no smoothing
    
    window_frames = max(1, int(smooth_ns / time_per_frame_ns))
    return (
        pd.Series(sasa)
        .rolling(window=window_frames, center=True, min_periods=1)
        .mean()
        .values
    )

def convert_frames_to_time(processed, base_dir):
    out = {}

    for label, data in processed.items():
        memb_idx = label.split("_")[-1]
        memb_dir = base_dir / f"memb-{memb_idx}"
        
        sim_time_ns = get_sim_time_ns(memb_dir)
        nframes = len(data["frames"])

        if sim_time_ns and nframes > 1:
            time_axis = np.linspace(0, sim_time_ns, nframes)
            dt = sim_time_ns / nframes
        else:
            time_axis = data["frames"]
            dt = None

        out[label] = {
            "frames": data["frames"],
            "time": time_axis,
            "sasa": data["sasa"],
            "time_per_frame_ns": dt
        }
    return out


def plot_trajectory(processed, save_dir: Path, x_axis="frames", smooth_ns=0.0):
    plt.figure(figsize=(18, 6))
    
    for label, data in processed.items():
        x = data["time"] if x_axis == "time" else data["frames"]

        # smooth SASA if enabled
        y = smooth_by_ns(
            data["sasa"],
            data.get("time_per_frame_ns", None),
            smooth_ns
        )

        plt.plot(x, y, label=label, alpha=0.8)

    plt.xlabel("Time (ns)" if x_axis=="time" else "Frame", fontsize=12)
    plt.ylabel("SASA (Å²)", fontsize=12)
    
    title = "LGWLAI Motif SASA"
    if smooth_ns > 0:
        title += f" ({smooth_ns} ns rolling mean)"
    plt.title(title, fontsize=14)

    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()

    suffix = f"{x_axis}_smooth" if smooth_ns > 0 else x_axis
    out = save_dir / f"sasa_plot_{suffix}.png"
    plt.savefig(out, dpi=600)
    print(f"[+] Saved {out}")

def save_stats(processed, save_dir: Path):

    stats_csv = save_dir / "stats.csv"

    with open(stats_csv, "w") as f:
        f.write("membrane,mean_sasa,std_sasa\n")
        for label, data in processed.items():
            mean = np.mean(data["sasa"])
            std = np.std(data["sasa"])
            f.write(f"{label},{mean:.6f},{std:.6f}\n")

    print(f"[+] CSV saved to {stats_csv}")


def plot_bar_means(processed, save_dir: Path):
    labels = list(processed.keys())
    means = [np.mean(processed[k]["sasa"]) for k in labels]
    stds  = [np.std(processed[k]["sasa"])  for k in labels]

    plt.figure(figsize=(8, 6))
    plt.bar(labels, means, yerr=stds, capsize=5, alpha=0.7)
    
    plt.ylabel("Mean SASA (Å²)")
    plt.title("Mean SASA Comparison")
    plt.grid(True, alpha=0.3, axis="y")

    out = save_dir / "average_sasa_plot.png"
    plt.savefig(out, dpi=300)
    print(f"[+] Saved {out}")


# -------- RUN PIPELINE --------
if __name__ == "__main__":
    processed, min_len = load_sasa_data(NPZ_FILE, TRUNCATE)
    print(f"Shortest trajectory length = {min_len}")

    if X_AXIS == "time":
        processed = convert_frames_to_time(processed, BASE_SIM_DIR)

    plot_trajectory(processed, DATA_DIR, x_axis=X_AXIS, smooth_ns=SMOOTH_NS)
    save_stats(processed, DATA_DIR)
    plot_bar_means(processed, DATA_DIR)
