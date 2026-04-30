# Data Preparation

## Obiettivo

Questa fase prepara il dataset per le successive analisi di structure learning e per l'addestramento dei modelli predittivi.

## Script disponibili

- `scripts/data_preparation/01_load_and_inspect.R`
- `scripts/data_preparation/02_prepare_data.R`

## Attivita' gia' implementate

### 1. Caricamento e ispezione iniziale

Lo script `01_load_and_inspect.R` e' dedicato al caricamento del dataset grezzo e all'esplorazione preliminare.

### 2. Preparazione del dataset

Lo script `02_prepare_data.R`:

- legge il dataset raw da `data/raw/`
- crea il dataset preparato `data/processed/diabetes_prepared.csv`
- trasforma alcune variabili continue in variabili categoriali:
  - `BMI_categoriale`
  - `MentHlth_categoriale`
  - `PhysHlth_categoriale`
- rimuove le versioni originali di `BMI`, `MentHlth` e `PhysHlth`
- legge le variabili escluse dai workflow DAG `AIC` e `BIC`
- crea anche gli split ridotti per gli scenari `aic_selection` e `bic_selection`

## Split del dataset

Lo script `02_prepare_data.R` usa un seed fisso (`123`) e produce:

- `data/processed/no_selection/training_set.csv`
- `data/processed/no_selection/validation_set.csv`
- `data/processed/no_selection/test_set.csv`
- `data/processed/no_selection/full_training_set.csv`

Il file `full_training_set.csv` e' costruito come unione di:

- `training_set`
- `validation_set`

La proporzione usata e':

- 70% training
- 20% validation
- 10% test

## Dataset per selezione variabili

Oltre allo scenario completo, lo script genera due famiglie di dataset ridotti:

- `data/processed/aic_selection/`
- `data/processed/bic_selection/`

Per ciascuna famiglia vengono salvati:

- `training_set_*`
- `validation_set_*`
- `test_set_*`
- `full_training_set_*`

Le colonne rimosse sono lette dai file prodotti dalla fase di structure learning:

- `reports/dag/aic/dag_markov_blanket_excluded_variables.csv`
- `reports/dag/bic/dag_markov_blanket_excluded_variables.csv`

Di conseguenza, lo script `02_prepare_data.R` richiede che gli output AIC/BIC della Markov blanket siano gia' presenti quando si vogliono rigenerare anche i dataset ridotti.

## Path centralizzati

I path dei dataset sono definiti in `project/config.R` e includono:

- `raw_data_path`
- `processed_data_path`
- `training_set_path`
- `validation_set_path`
- `test_set_path`
- `full_training_set_path`
- `aic_training_set_path`
- `aic_validation_set_path`
- `aic_test_set_path`
- `aic_full_training_set_path`
- `bic_training_set_path`
- `bic_validation_set_path`
- `bic_test_set_path`
- `bic_full_training_set_path`

## Ruolo nella pipeline

Attualmente:

- i DAG vengono appresi sul training set completo, cioe' `data/processed/no_selection/training_set.csv`
- i modelli finali BART, Neural Network, Naive Bayes e TAN vengono addestrati sui rispettivi `full_training_set`
- gli scenari `aic_selection` e `bic_selection` usano solo le covariate selezionate dalla Markov blanket del relativo DAG
