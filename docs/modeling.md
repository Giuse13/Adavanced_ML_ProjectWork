# Modeling

## Obiettivo

Questa fase addestra modelli predittivi per `Diabetes_binary` usando BART e Naive Bayes, confrontando tre insiemi di covariate:

- nessuna selezione variabili
- selezione tramite Markov blanket del DAG con score `AIC`
- selezione tramite Markov blanket del DAG con score `BIC`

## Struttura degli script

La logica comune dei modelli BART e' centralizzata in:

- `scripts/modeling/bart/_common.R`

Gli script BART specifici per scenario sono:

- `scripts/modeling/bart/no_selection/validation.R`
- `scripts/modeling/bart/no_selection/training.R`
- `scripts/modeling/bart/aic_selection/validation.R`
- `scripts/modeling/bart/aic_selection/training.R`
- `scripts/modeling/bart/bic_selection/validation.R`
- `scripts/modeling/bart/bic_selection/training.R`

La logica comune dei modelli Naive Bayes e' centralizzata in:

- `scripts/modeling/naive_bayes/_common.R`

Gli script Naive Bayes specifici per scenario sono:

- `scripts/modeling/naive_bayes/no_selection/training.R`
- `scripts/modeling/naive_bayes/aic_selection/training.R`
- `scripts/modeling/naive_bayes/bic_selection/training.R`

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

Significato degli iperparametri:

- `ntree`: numero di alberi usati dal modello BART. Valori piu' alti aumentano la flessibilita' del modello, ma anche il costo computazionale.
- `k`: parametro di shrinkage che controlla quanto ciascun albero puo' contribuire alla previsione finale. Valori piu' alti rendono il contributo dei singoli alberi piu' conservativo.
- `power`: parametro della prior sulla profondita' degli alberi. Influenza la probabilita' che un nodo venga ulteriormente splittato al crescere della profondita'.
- `base`: parametro della prior sulla struttura degli alberi. Insieme a `power`, controlla quanto gli alberi tendono a rimanere piccoli o profondi.
- `ndpost`: numero di campioni posteriori mantenuti dopo il burn-in. Aumentarlo puo' rendere piu' stabile la stima, ma allunga il tempo di esecuzione.
- `nskip`: numero di iterazioni iniziali scartate come burn-in prima di salvare i campioni posteriori.

## Funzioni comuni Naive Bayes

Il file `scripts/modeling/naive_bayes/_common.R` contiene:

- controllo della disponibilita' di `bnlearn`
- caricamento dei dataset
- conversione di tutte le variabili in `factor`
- costruzione della struttura Naive Bayes con `bnlearn::naive.bayes`
- stima dei parametri con `bnlearn::bn.fit(..., method = "bayes")`
- salvataggio del model bundle finale

I modelli Naive Bayes non hanno una griglia di iperparametri in questo progetto: vengono quindi addestrati direttamente sui rispettivi `full_training_set`.

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

## Workflow di training finale BART

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

## Workflow di training finale Naive Bayes

Ogni script `training.R`:

- legge il rispettivo `full_training_set`
- converte target e covariate in `factor`
- addestra il modello Naive Bayes discreto
- salva il modello `.rds` nella cartella `models/naive_bayes/`

Comandi:

```r
source("scripts/modeling/naive_bayes/no_selection/training.R")
source("scripts/modeling/naive_bayes/aic_selection/training.R")
source("scripts/modeling/naive_bayes/bic_selection/training.R")
```

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
- `models/naive_bayes/no_selection/naive_bayes_model_no_selection.rds`
- `models/naive_bayes/aic/naive_bayes_model_aic.rds`
- `models/naive_bayes/bic/naive_bayes_model_bic.rds`

I file `.rds` dei modelli sono artefatti generati e possono essere molto pesanti. Per questo sono esclusi da Git tramite `.gitignore`.

## Ordine consigliato

1. Preparare i dataset con `scripts/data_preparation/02_prepare_data.R`.
2. Generare le selezioni AIC/BIC con gli script in `scripts/structure_learning/`.
3. Eseguire la validazione BART per gli scenari desiderati.
4. Eseguire il training finale BART per gli scenari validati.
5. Eseguire il training finale Naive Bayes per gli scenari desiderati.
6. Usare i file in `reports/modeling/bart/` per confrontare le prestazioni di validazione BART.
