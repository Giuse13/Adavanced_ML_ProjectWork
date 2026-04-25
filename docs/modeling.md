# Modeling

## Obiettivo

Questa fase addestra modelli predittivi per `Diabetes_binary` usando BART e confronta tre insiemi di covariate:

- nessuna selezione variabili
- selezione tramite Markov blanket del DAG con score `AIC`
- selezione tramite Markov blanket del DAG con score `BIC`

## Struttura degli script

La logica comune dei modelli BART e' centralizzata in:

- `scripts/modeling/bart/_common.R`

Gli script specifici per scenario sono:

- `scripts/modeling/bart/no_selection/validation.R`
- `scripts/modeling/bart/no_selection/training.R`
- `scripts/modeling/bart/aic_selection/validation.R`
- `scripts/modeling/bart/aic_selection/training.R`
- `scripts/modeling/bart/bic_selection/validation.R`
- `scripts/modeling/bart/bic_selection/training.R`

## Funzioni comuni BART

Il file `_common.R` contiene:

- caricamento dei dataset
- preparazione di `x` e `y`
- costruzione delle matrici tramite `model.matrix`
- griglia di iperparametri BART
- fitting con `gbart(..., type = "pbart")`
- calcolo dell'accuracy sul validation set
- salvataggio dei risultati di validazione
- caricamento dei best params
- training finale del modello

La griglia attuale e':

- `ntree = 30, 50, 100`
- `k = 1, 2`
- `power = 2, 3`
- `base = 0.95`
- `ndpost = 400`
- `nskip = 100`

Il totale e' di 12 combinazioni.

## Workflow di validazione

Ogni script `validation.R`:

- legge il training set dello scenario
- legge il validation set dello scenario
- valuta tutte le combinazioni della griglia BART
- ordina i risultati per accuracy decrescente
- salva tutti i risultati in `validation_results_*.csv`
- salva la migliore combinazione in `best_params_*.csv`

Comandi:

```r
source("scripts/modeling/bart/no_selection/validation.R")
source("scripts/modeling/bart/aic_selection/validation.R")
source("scripts/modeling/bart/bic_selection/validation.R")
```

## Workflow di training finale

Ogni script `training.R`:

- legge il file `best_params_*.csv` prodotto dalla validazione
- legge il rispettivo `full_training_set`
- addestra il modello finale con i migliori parametri
- salva il modello `.rds` nella cartella `models/bart/`

Comandi:

```r
source("scripts/modeling/bart/no_selection/training.R")
source("scripts/modeling/bart/aic_selection/training.R")
source("scripts/modeling/bart/bic_selection/training.R")
```

Gli script di training sono indipendenti dagli script di validazione: richiedono solo che il relativo file `best_params_*.csv` esista gia'.

## Dataset usati

Scenario senza selezione:

- `data/processed/no_selection/training_set.csv`
- `data/processed/no_selection/validation_set.csv`
- `data/processed/no_selection/full_training_set.csv`

Scenario AIC:

- `data/processed/aic_selection/training_set_aic.csv`
- `data/processed/aic_selection/validation_set_aic.csv`
- `data/processed/aic_selection/full_training_set_aic.csv`

Scenario BIC:

- `data/processed/bic_selection/training_set_bic.csv`
- `data/processed/bic_selection/validation_set_bic.csv`
- `data/processed/bic_selection/full_training_set_bic.csv`

## Output prodotti

Validazione:

- `reports/modeling/bart/no_selection/validation_results_no_selection.csv`
- `reports/modeling/bart/no_selection/best_params_no_selection.csv`
- `reports/modeling/bart/aic/validation_results_aic.csv`
- `reports/modeling/bart/aic/best_params_aic.csv`
- `reports/modeling/bart/bic/validation_results_bic.csv`
- `reports/modeling/bart/bic/best_params_bic.csv`

Training finale:

- `models/bart/no_selection/bart_model_no_selection.rds`
- `models/bart/aic/bart_model_aic.rds`
- `models/bart/bic/bart_model_bic.rds`

I file `.rds` dei modelli sono artefatti generati e possono essere molto pesanti. Per questo sono esclusi da Git tramite `.gitignore`.

## Ordine consigliato

1. Preparare i dataset con `scripts/data_preparation/02_prepare_data.R`.
2. Generare le selezioni AIC/BIC con gli script in `scripts/structure_learning/`.
3. Eseguire la validazione BART per gli scenari desiderati.
4. Eseguire il training finale per gli scenari validati.
5. Usare i file in `reports/modeling/bart/` per confrontare le prestazioni.
