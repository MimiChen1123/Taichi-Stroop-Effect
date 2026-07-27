# Taichi Stroop Effect

This project explores a Stroop-like effect involving object-color association. The experiment was implemented in Processing, and the collected trial results can be analyzed with Python scripts.

For more details, see the paper: [Exploring the Stroop Effect of Object-Color Association.pdf](Exploring%20the%20Stroop%20Effect%20of%20Object-Color%20Association.pdf)

## Project Structure

```text
.
├── Exploring the Stroop Effect of Object-Color Association.pdf
├── visual/
│   ├── visual.pde
│   ├── sketch.properties
│   └── analyze/
│       ├── analyze_experiment_results.py
│       └── draw_bar_charts.py
```

## Experiment

The Processing sketch is located in `visual/visual.pde`.

To run the experiment:

1. Open the `visual/` folder in Processing.
2. Run the sketch.
3. Enter the participant name when prompted.
4. Complete the fruit-color mapping and response trials.

The sketch records trial-level data such as word type, congruency, response correctness, reaction time, and fruit-color mapping.

## Analysis

The analysis scripts are in `visual/analyze/`.

`analyze_experiment_results.py` reads CSV files from a `results/` folder, combines the data, summarizes accuracy and reaction time by condition, and saves analysis outputs.

`draw_bar_charts.py` generates bar charts based on the reported delta values.

Required Python packages:

```bash
pip install pandas matplotlib numpy
```

Run the analysis from the `visual/` directory:

```bash
cd visual
python analyze/analyze_experiment_results.py
python analyze/draw_bar_charts.py
```

## Notes

Participant result CSV files are not required for running the Processing sketch. If publishing raw results, anonymize participant names before uploading to a public repository.
