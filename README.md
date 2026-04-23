# Adavanced_ML_ProjectWork

Questo repository e' organizzato per un progetto di machine learning in R: analisi dei dati, preparazione del dataset, addestramento dei modelli e valutazione finale.

## Stato attuale

Ad oggi il progetto include:

- caricamento ed esplorazione iniziale del dataset
- preparazione del dataset e costruzione di variabili categoriali derivate
- split in `training`, `validation`, `test` e `full_training`
- apprendimento di DAG con hill climbing e score `AIC`
- apprendimento di DAG con hill climbing e score `BIC`
- estrazione della Markov blanket di `Diabetes_binary`
- confronto della selezione variabili tra `AIC` e `BIC` in formato Excel

Per la documentazione dettagliata:

- [docs/data_preparation.md](docs/data_preparation.md)
- [docs/structure_learning.md](docs/structure_learning.md)

## Ambiente R

- `.Rprofile` viene eseguito automaticamente quando si apre il progetto.
- La cartella `ambiente_progettodallavalle/` viene usata come prima libreria R del progetto.
- La cartella dell'ambiente e `.vscode/settings.json` restano locali e non vengono pushati.

Per controllare l'ambiente attivo:

```r
source("project/setup_progetto.R")
```

Per installare un pacchetto nell'ambiente del progetto:

```r
install.packages("readr", lib = .libPaths()[1])
```

## Flusso di lavoro

1. Mettere i dati originali in `data/raw/`.
2. Esplorare e pulire i dati con gli script in `scripts/data_preparation/`.
3. Costruire i DAG e analizzare la struttura con gli script in `scripts/structure_learning/`.
4. Addestrare i modelli con gli script in `scripts/modeling/`.
5. Valutare i risultati con gli script in `scripts/evaluation/`.
6. Salvare output, metriche e grafici nelle cartelle `reports/` e nelle relative sottocartelle.

## Script principali

- `scripts/data_preparation/01_load_and_inspect.R`: caricamento del dataset e ispezione iniziale.
- `scripts/data_preparation/02_prepare_data.R`: creazione del dataset preparato, split in `training/validation/test` e costruzione del `full_training_set`.
- `scripts/structure_learning/01_learn_dag_hc_aic.R`: confronto di configurazioni `AIC`, selezione del DAG migliore e generazione degli output in `reports/dag/aic/`.
- `scripts/structure_learning/02_learn_dag_hc_bic.R`: confronto di configurazioni `BIC`, selezione del DAG migliore e generazione degli output in `reports/dag/bic/`.
- `scripts/structure_learning/03_export_variable_selection_comparison.R`: creazione del file Excel di confronto tra selezione variabili `AIC` e `BIC`.

## Struttura del progetto

- `.Rprofile`: attiva automaticamente la libreria locale del progetto.
- `project/`: configurazione condivisa del progetto.
  Include `config.R` con i percorsi condivisi del progetto.
- `docs/`: documentazione sintetica delle fasi gia' implementate.
- `data/raw/`: dati originali.
- `data/processed/`: dati puliti o trasformati, inclusi `training_set`, `validation_set`, `test_set` e `full_training_set`.
- `scripts/data_preparation/`: import, pulizia, feature engineering.
- `scripts/structure_learning/`: apprendimento dei DAG, Markov blanket e confronto AIC/BIC.
- `scripts/modeling/`: training e confronto modelli.
- `scripts/evaluation/`: metriche, grafici e validazione.
- `scripts/utils/`: funzioni riutilizzabili.
- `reports/analisi_esplorativa/`: output dell'analisi esplorativa, incluse figure e file Excel.
- `reports/dag/aic/`: output del DAG appreso con score `AIC`.
- `reports/dag/bic/`: output del DAG appreso con score `BIC`.
- `reports/dag/variable_selection_aic_vs_bic.xlsx`: confronto in Excel della selezione variabili tra `AIC` e `BIC`.
- `reports/results/`: tabelle, metriche e output finali.
- `ambiente_progettodallavalle/`: libreria locale R esclusa da Git.
