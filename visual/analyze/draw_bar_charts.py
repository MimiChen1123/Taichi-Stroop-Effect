import matplotlib.pyplot as plt
import numpy as np

# -----------------------------
# Data from Table 2
# -----------------------------

# Congruency effect: Mismatch - Match
congruency_labels = ["Color", "Fruit"]
congruency_acc = [-4.9, -8.2]
congruency_rt = [138.1, 62.5]

# Type effect: Fruit - Color
type_labels = ["Match", "Mismatch"]
type_acc = [0.6, -2.7]
type_rt = [19.3, -56.3]

accuracy_colors = ["#4C78A8", "#8DB7D7"]
rt_colors = ["#F58518", "#FFB36A"]


# -----------------------------
# Helper function
# -----------------------------

def draw_bar(ax, labels, values, ylabel, colors):
    x = np.arange(len(labels))

    bars = ax.bar(x, values, color=colors)
    
    y_min = min(0, min(values))
    y_max = max(0, max(values))
    # if y_min < 0:
    padding = (y_max - y_min) * 0.1
    ax.set_ylim(y_min - (padding if y_min < 0 else 0), y_max + padding)
    
    # zero line
    ax.axhline(0, color="black", linewidth=1)

    # x-axis labels
    ax.set_xticks(x)
    ax.set_xticklabels(labels, fontsize=11)

    # y-axis label
    ax.set_ylabel(ylabel, fontsize=11)

    # remove unnecessary borders
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    # value labels
    for bar, value in zip(bars, values):
        height = bar.get_height()

        if value >= 0:
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                height,
                f"{value:+.1f}",
                ha="center",
                va="bottom",
                fontsize=10
            )
        else:
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                height - (padding * 0.08),  # slightly above the bar for negative values
                f"{value:+.1f}",
                ha="center",
                va="top",
                fontsize=10
            )


def save_bar_chart(labels, values, ylabel, colors, filename):
    fig, ax = plt.subplots(figsize=(5, 4))
    draw_bar(ax, labels, values, ylabel, colors)
    fig.tight_layout()
    fig.savefig(filename, dpi=300, bbox_inches="tight")
    plt.close(fig)


# -----------------------------
# Draw and save separate figures
# -----------------------------

save_bar_chart(
    congruency_labels,
    congruency_acc,
    "Δ Accuracy (%)",
    accuracy_colors,
    "analysis_output/congruency_accuracy_bar_chart.png"
)

save_bar_chart(
    congruency_labels,
    congruency_rt,
    "Δ RT (ms)",
    rt_colors,
    "analysis_output/congruency_rt_bar_chart.png"
)

save_bar_chart(
    type_labels,
    type_acc,
    "Δ Accuracy (%)",
    accuracy_colors,
    "analysis_output/type_accuracy_bar_chart.png"
)

save_bar_chart(
    type_labels,
    type_rt,
    "Δ RT (ms)",
    rt_colors,
    "analysis_output/type_rt_bar_chart.png"
)
