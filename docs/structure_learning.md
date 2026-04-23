# Structure Learning

## Obiettivo

Questa fase apprende la struttura di una Bayesian Network sulle variabili del dataset usando l'algoritmo hill climbing.

La variabile risposta considerata nel progetto e':

- `Diabetes_binary`

## Dataset usato

I DAG sono attualmente costruiti sul file:

- `data/processed/training_set.csv`

La scelta e' coerente con il fatto che la Markov blanket e la successiva selezione variabili devono essere stimate sul training set.

## Script disponibili

- `scripts/structure_learning/01_learn_dag_hc_aic.R`
- `scripts/structure_learning/02_learn_dag_hc_bic.R`
- `scripts/structure_learning/03_export_variable_selection_comparison.R`

## Workflow AIC

Lo script `01_learn_dag_hc_aic.R`:

- legge il `training_set`
- converte tutte le colonne in `factor`
- confronta piu' configurazioni di `hc()` con score `AIC`
- seleziona automaticamente il DAG migliore
- salva gli output in `reports/dag/aic/`

La griglia attuale e':

- `restart = 10, 20, 50, 100`
- `perturb = 2, 3, 4`

Output prodotti:

- `dag_configuration_comparison.csv`
- `dag_hc_aic_best_model.rds`
- `dag_hc_aic_best_arcs.csv`
- `dag_hc_aic_plot.svg`
- `dag_markov_blanket_diabetes.svg`
- `dag_markov_blanket_selected_variables.csv`
- `dag_markov_blanket_excluded_variables.csv`

## Workflow BIC

Lo script `02_learn_dag_hc_bic.R` replica la stessa logica del workflow `AIC`, ma con score `BIC`.

Output prodotti in `reports/dag/bic/`:

- `dag_configuration_comparison.csv`
- `dag_hc_bic_best_model.rds`
- `dag_hc_bic_best_arcs.csv`
- `dag_hc_bic_plot.svg`
- `dag_markov_blanket_diabetes.svg`
- `dag_markov_blanket_selected_variables.csv`
- `dag_markov_blanket_excluded_variables.csv`

## Markov blanket e selezione variabili

Per entrambi i criteri:

- viene estratta la Markov blanket di `Diabetes_binary`
- vengono salvate separatamente le variabili selezionate e quelle non selezionate

La Markov blanket rappresenta l'insieme minimo di variabili tale che, condizionando su di esse, `Diabetes_binary` risulta indipendente da tutte le altre variabili del DAG.

## Confronto AIC vs BIC

Lo script `03_export_variable_selection_comparison.R` costruisce un file Excel per la presentazione:

- `reports/dag/variable_selection_aic_vs_bic.xlsx`

Il file contiene:

- una riga per ogni variabile del `training_set`, esclusa `Diabetes_binary`
- una colonna `AIC`
- una colonna `BIC`
- evidenziazione visiva della selezione:
  - verde = variabile selezionata
  - rosso chiaro = variabile non selezionata

## Note interpretative

- `AIC` tende a produrre DAG piu' densi
- `BIC` tende a produrre DAG piu' parsimoniosi
- il confronto tra i due criteri e' utile sia per l'interpretazione causale sia per una possibile selezione di covariate da usare nei modelli predittivi
