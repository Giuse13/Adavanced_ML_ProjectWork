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

## Split del dataset

Lo script `02_prepare_data.R` usa un seed fisso (`123`) e produce:

- `training_set.csv`
- `validation_set.csv`
- `test_set.csv`
- `full_training_set.csv`

Il file `full_training_set.csv` e' costruito come unione di:

- `training_set`
- `validation_set`

## Path centralizzati

I path dei dataset sono definiti in `project/config.R` e includono:

- `raw_data_path`
- `processed_data_path`
- `training_set_path`
- `validation_set_path`
- `test_set_path`
- `full_training_set_path`

## Ruolo nella pipeline

Attualmente:

- i DAG vengono appresi su `training_set.csv`
- il `full_training_set.csv` e' disponibile per usi successivi, ad esempio training finale di modelli predittivi
