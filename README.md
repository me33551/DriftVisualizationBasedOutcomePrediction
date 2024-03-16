# Drift Visualization Based Outcome Prediction
This repository describes how to reproduce the evaluation results of the paper "Interactive Drift Visualization in Sensor Data Streams for Explainable Process Outcome Prediction". The described steps are intended to be carried out on Linux - for other operating systems the commands may slightly differ.

## Setup
After cloning the repository make sure that ruby as well as julia are correctly installed.
Then complete the following steps:
<ul>
  <li>Check if the ruby dependencies are met with "bundle check" - if not install them with "bundle install"</li>
  <li>Install the julia dependencies defined in the environment "MyDependencie" - follow the guide avaialable on [https://pkgdocs.julialang.org/v1/environments/](https://pkgdocs.julialang.org/v1/environments/#Using-someone-else's-project) </li>
</ul>
Run the server made available in the other repository linked in the paper (https://anonymous.4open.science/r/paper_drift_visualization-FC64/README.md)
Afterwards, execute the setup script ("sh setup.sh")

## Running Evaluation
For reproducing the evaluation results execute the "evaluation.sh" script ("sh evaluation.sh"). The console output represents the raw data for creating the table in the evaluation section

## Cleanup
To restore folders/files to their initial state execute the "cleanup.sh" script ("sh cleanup.sh"). This should delete all created folders and reset changed files.
