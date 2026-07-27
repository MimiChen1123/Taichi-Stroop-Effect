import os
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt


# ============================================================
# Settings
# ============================================================
RESULTS_DIR = "results"
OUTPUT_DIR = "analysis_output"

# Reaction time 要不要只計算答對的 trials
# True  = 只計算答對題目的 RT，通常心理實驗較常用
# False = 所有題目都納入 RT
RT_CORRECT_ONLY = True


# ============================================================
# Helper functions
# ============================================================
def load_all_results(results_dir: str) -> pd.DataFrame:
    """
    Read all CSV files in results_dir and combine them into one DataFrame.
    Each row will keep its source filename in the column 'source_file'.
    """
    results_path = Path(results_dir)

    if not results_path.exists():
        raise FileNotFoundError(f"Cannot find folder: {results_dir}")

    csv_files = sorted(results_path.glob("*.csv"))

    if len(csv_files) == 0:
        raise FileNotFoundError(f"No CSV files found in folder: {results_dir}")

    all_dfs = []

    for csv_file in csv_files:
        df = pd.read_csv(csv_file)
        df["source_file"] = csv_file.name
        all_dfs.append(df)

    combined_df = pd.concat(all_dfs, ignore_index=True)
    return combined_df


def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean required columns and convert types.
    """
    required_columns = [
        "word_type",
        "congruency",
        "is_correct",
        "reaction_time_ms",
    ]

    missing_columns = [col for col in required_columns if col not in df.columns]
    if missing_columns:
        raise ValueError(f"Missing required columns: {missing_columns}")

    df = df.copy()

    # Convert is_correct to boolean
    # This handles True/False, "true"/"false", 1/0, etc.
    if df["is_correct"].dtype != bool:
        df["is_correct"] = (
            df["is_correct"]
            .astype(str)
            .str.strip()
            .str.lower()
            .map({
                "true": True,
                "false": False,
                "1": True,
                "0": False,
                "yes": True,
                "no": False,
            })
        )

    # Convert reaction_time_ms to numeric
    df["reaction_time_ms"] = pd.to_numeric(
        df["reaction_time_ms"],
        errors="coerce"
    )

    # Remove rows with invalid core values
    df = df.dropna(
        subset=[
            "word_type",
            "congruency",
            "is_correct",
            "reaction_time_ms",
        ]
    )

    # Create combined condition label
    df["condition"] = (
        df["word_type"].astype(str) + " | " + df["congruency"].astype(str)
    )

    return df


def summarize_by_condition(
    df: pd.DataFrame,
    rt_correct_only: bool = True
) -> pd.DataFrame:
    """
    Compute accuracy and reaction time for each word_type x congruency condition.
    """
    # Accuracy: all trials
    acc_summary = (
        df.groupby(["word_type", "congruency"], as_index=False)
        .agg(
            n_trials=("is_correct", "count"),
            n_correct=("is_correct", "sum"),
            accuracy=("is_correct", "mean"),
        )
    )

    # Reaction time: correct-only or all trials
    if rt_correct_only:
        rt_df = df[df["is_correct"] == True].copy()
    else:
        rt_df = df.copy()

    rt_summary = (
        rt_df.groupby(["word_type", "congruency"], as_index=False)
        .agg(
            mean_reaction_time_ms=("reaction_time_ms", "mean"),
            sd_reaction_time_ms=("reaction_time_ms", "std"),
            median_reaction_time_ms=("reaction_time_ms", "median"),
        )
    )

    summary = acc_summary.merge(
        rt_summary,
        on=["word_type", "congruency"],
        how="left",
    )

    summary["accuracy_percent"] = summary["accuracy"] * 100
    summary["condition"] = (
        summary["word_type"].astype(str)
        + " | "
        + summary["congruency"].astype(str)
    )

    return summary


def reorder_pivot_table(
    pivot_df: pd.DataFrame,
    preferred_index_order: list,
    preferred_column_order: list,
) -> pd.DataFrame:
    """
    Reorder pivot table index and columns if preferred labels exist.
    This keeps plots in a stable and readable order.
    """
    existing_index_order = [
        x for x in preferred_index_order if x in pivot_df.index
    ]
    remaining_index_order = [
        x for x in pivot_df.index if x not in existing_index_order
    ]
    pivot_df = pivot_df.loc[existing_index_order + remaining_index_order]

    existing_column_order = [
        x for x in preferred_column_order if x in pivot_df.columns
    ]
    remaining_column_order = [
        x for x in pivot_df.columns if x not in existing_column_order
    ]
    pivot_df = pivot_df[existing_column_order + remaining_column_order]

    return pivot_df


# ============================================================
# Plot 1: Four conditions directly
# ============================================================
def plot_accuracy_by_condition(summary: pd.DataFrame, output_path: str):
    """
    Plot accuracy for four experimental conditions directly.
    x-axis = color_word match / color_word mismatch / fruit_word match / fruit_word mismatch
    """
    plot_df = summary.sort_values(["word_type", "congruency"]).copy()
    plot_df["plot_label"] = (
        plot_df["word_type"].astype(str)
        + ",\n"
        + plot_df["congruency"].astype(str)
    )

    bar_colors = ["#8ecae6", "#2162bc", "#40fea5", "#38b160"]

    plt.figure(figsize=(10, 6))
    bars = plt.bar(
        plot_df["plot_label"],
        plot_df["accuracy_percent"],
        width=0.5,
        color=bar_colors[:len(plot_df)],
    )

    for bar, value in zip(bars, plot_df["accuracy_percent"]):
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 1,
            f"{value:.1f}%",
            ha="center",
            va="bottom",
            fontsize=10,
        )

    plt.ylabel(
        "Accuracy (%)",
        fontweight="bold",
        fontsize=12,
    )
    plt.xlabel(
        "Condition (word_type | congruency)",
        fontweight="bold",
        fontsize=12,
    )
    plt.title(
        "Accuracy by Condition",
        fontweight="bold",
        fontsize=14,
    )
    plt.ylim(0, 106)
    plt.tight_layout()
    plt.savefig(output_path, dpi=300)
    plt.close()


def plot_reaction_time_by_condition(summary: pd.DataFrame, output_path: str):
    """
    Plot mean reaction time for four experimental conditions directly.
    x-axis = color_word match / color_word mismatch / fruit_word match / fruit_word mismatch
    """
    plot_df = summary.sort_values(["word_type", "congruency"]).copy()
    plot_df["plot_label"] = (
        plot_df["word_type"].astype(str)
        + ",\n"
        + plot_df["congruency"].astype(str)
    )

    bar_colors = ["#8ecae6", "#2162bc", "#40fea5", "#38b160"]

    plt.figure(figsize=(10, 6))
    bars = plt.bar(
        plot_df["plot_label"],
        plot_df["mean_reaction_time_ms"],
        width=0.5,
        color=bar_colors[:len(plot_df)],
    )

    for bar, value in zip(bars, plot_df["mean_reaction_time_ms"]):
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 5,
            f"{value:.1f} ms",
            ha="center",
            va="bottom",
            fontsize=10,
        )

    plt.ylabel(
        "Mean Reaction Time (ms)",
        fontweight="bold",
        fontsize=12,
    )
    plt.xlabel(
        "Condition (word_type | congruency)",
        fontweight="bold",
        fontsize=12,
    )
    plt.title(
        "Reaction Time by Condition",
        fontweight="bold",
        fontsize=14,
    )
    plt.tight_layout()
    plt.savefig(output_path, dpi=300)
    plt.close()


# ============================================================
# Plot 2: x-axis = word_type, bars = congruency
# ============================================================
def plot_accuracy_grouped_by_word_type(summary: pd.DataFrame, output_path: str):
    """
    Plot grouped bar chart:
    x-axis = word_type
    bars = congruency
    y-axis = accuracy
    """
    pivot_df = summary.pivot(
        index="word_type",
        columns="congruency",
        values="accuracy_percent",
    )

    pivot_df = reorder_pivot_table(
        pivot_df,
        preferred_index_order=["color_word", "fruit_word"],
        preferred_column_order=["match", "mismatch"],
    )

    bar_colors = ["#8ecae6", "#2162bc"]

    ax = pivot_df.plot(
        kind="bar",
        figsize=(10, 6),
        width=0.5,
        color=bar_colors[:len(pivot_df.columns)],
    )

    for container in ax.containers:
        ax.bar_label(
            container,
            fmt="%.1f%%",
            padding=3,
            fontsize=10,
        )

    ax.set_ylabel(
        "Accuracy (%)",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_xlabel(
        "Word Type",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_title(
        "Accuracy by Word Type and Congruency",
        fontweight="bold",
        fontsize=14,
    )
    ax.set_ylim(0, 106)

    plt.xticks(rotation=0)
    plt.legend(
        title="Congruency",
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
    )
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()


def plot_reaction_time_grouped_by_word_type(summary: pd.DataFrame, output_path: str):
    """
    Plot grouped bar chart:
    x-axis = word_type
    bars = congruency
    y-axis = mean reaction time
    """
    pivot_df = summary.pivot(
        index="word_type",
        columns="congruency",
        values="mean_reaction_time_ms",
    )

    pivot_df = reorder_pivot_table(
        pivot_df,
        preferred_index_order=["color_word", "fruit_word"],
        preferred_column_order=["match", "mismatch"],
    )

    bar_colors = ["#8ecae6", "#2162bc"]

    ax = pivot_df.plot(
        kind="bar",
        figsize=(10, 6),
        width=0.6,
        color=bar_colors[:len(pivot_df.columns)],
    )

    for container in ax.containers:
        ax.bar_label(
            container,
            fmt="%.1f ms",
            padding=3,
            fontsize=10,
        )

    ax.set_ylabel(
        "Mean Reaction Time (ms)",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_xlabel(
        "Word Type",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_title(
        "Mean Reaction Time by Word Type and Congruency",
        fontweight="bold",
        fontsize=14,
    )

    plt.xticks(rotation=0)
    plt.legend(
        title="Congruency",
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
    )
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()


# ============================================================
# Plot 3: x-axis = congruency, bars = word_type
# ============================================================
def plot_accuracy_grouped_by_congruency(summary: pd.DataFrame, output_path: str):
    """
    Plot grouped bar chart:
    x-axis = congruency
    bars = word_type
    y-axis = accuracy
    """
    pivot_df = summary.pivot(
        index="congruency",
        columns="word_type",
        values="accuracy_percent",
    )

    pivot_df = reorder_pivot_table(
        pivot_df,
        preferred_index_order=["match", "mismatch"],
        preferred_column_order=["color_word", "fruit_word"],
    )

    bar_colors = ["#8ecae6", "#40fea5"]

    ax = pivot_df.plot(
        kind="bar",
        figsize=(10, 6),
        width=0.6,
        color=bar_colors[:len(pivot_df.columns)],
    )

    for container in ax.containers:
        ax.bar_label(
            container,
            fmt="%.1f%%",
            padding=3,
            fontsize=10,
        )

    ax.set_ylabel(
        "Accuracy (%)",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_xlabel(
        "Congruency",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_title(
        "Accuracy by Congruency and Word Type",
        fontweight="bold",
        fontsize=14,
    )
    ax.set_ylim(0, 106)

    plt.xticks(rotation=0)
    plt.legend(
        title="Word Type",
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
    )
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()


def plot_reaction_time_grouped_by_congruency(summary: pd.DataFrame, output_path: str):
    """
    Plot grouped bar chart:
    x-axis = congruency
    bars = word_type
    y-axis = mean reaction time
    """
    pivot_df = summary.pivot(
        index="congruency",
        columns="word_type",
        values="mean_reaction_time_ms",
    )

    pivot_df = reorder_pivot_table(
        pivot_df,
        preferred_index_order=["match", "mismatch"],
        preferred_column_order=["color_word", "fruit_word"],
    )

    bar_colors = ["#8ecae6", "#40fea5"]

    ax = pivot_df.plot(
        kind="bar",
        figsize=(10, 6),
        width=0.6,
        color=bar_colors[:len(pivot_df.columns)],
    )

    for container in ax.containers:
        ax.bar_label(
            container,
            fmt="%.1f ms",
            padding=3,
            fontsize=10,
        )

    ax.set_ylabel(
        "Mean Reaction Time (ms)",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_xlabel(
        "Congruency",
        fontweight="bold",
        fontsize=12,
    )
    ax.set_title(
        "Mean Reaction Time by Congruency and Word Type",
        fontweight="bold",
        fontsize=14,
    )

    plt.xticks(rotation=0)
    plt.legend(
        title="Word Type",
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
    )
    plt.tight_layout()
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()


# ============================================================
# Main
# ============================================================
def main():
    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(parents=True, exist_ok=True)

    # 1. Read all experiment result files
    df = load_all_results(RESULTS_DIR)

    # 2. Clean data
    df = clean_data(df)

    # 3. Save combined raw data
    combined_csv_path = output_path / "combined_results.csv"
    df.to_csv(combined_csv_path, index=False, encoding="utf-8-sig")

    # 4. Summarize by word_type x congruency
    summary = summarize_by_condition(
        df,
        rt_correct_only=RT_CORRECT_ONLY,
    )

    summary_csv_path = output_path / "summary_by_word_type_and_congruency.csv"
    summary.to_csv(summary_csv_path, index=False, encoding="utf-8-sig")

    # 5. Plot figures

    # A. Four-condition figures
    plot_accuracy_by_condition(
        summary,
        output_path / "accuracy_by_condition.png",
    )

    plot_reaction_time_by_condition(
        summary,
        output_path / "reaction_time_by_condition.png",
    )

    # B. Grouped by word_type
    plot_accuracy_grouped_by_word_type(
        summary,
        output_path / "accuracy_grouped_by_word_type_and_congruency.png",
    )

    plot_reaction_time_grouped_by_word_type(
        summary,
        output_path / "reaction_time_grouped_by_word_type_and_congruency.png",
    )

    # C. Grouped by congruency
    plot_accuracy_grouped_by_congruency(
        summary,
        output_path / "accuracy_grouped_by_congruency_and_word_type.png",
    )

    plot_reaction_time_grouped_by_congruency(
        summary,
        output_path / "reaction_time_grouped_by_congruency_and_word_type.png",
    )

    # 6. Print result
    print("Analysis finished.")
    print(f"Loaded trials: {len(df)}")
    print()
    print("Output files:")
    print(f"- {combined_csv_path}")
    print(f"- {summary_csv_path}")
    print(f"- {output_path / 'accuracy_by_condition.png'}")
    print(f"- {output_path / 'reaction_time_by_condition.png'}")
    print(f"- {output_path / 'accuracy_grouped_by_word_type_and_congruency.png'}")
    print(f"- {output_path / 'reaction_time_grouped_by_word_type_and_congruency.png'}")
    print(f"- {output_path / 'accuracy_grouped_by_congruency_and_word_type.png'}")
    print(f"- {output_path / 'reaction_time_grouped_by_congruency_and_word_type.png'}")
    print()
    print("Summary:")
    print(summary)


if __name__ == "__main__":
    main()