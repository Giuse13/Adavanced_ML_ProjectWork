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
- costruzione dei dataset scenario-specifici per `no_selection`, `aic_selection` e `bic_selection`
- training e validazione di modelli BART per `no_selection`, `aic_selection` e `bic_selection`
- training diretto di modelli Naive Bayes per `no_selection`, `aic_selection` e `bic_selection`
- training diretto di modelli TAN per `no_selection`, `aic_selection` e `bic_selection`
- valutazione dei modelli BART, Naive Bayes e TAN finali tramite accuracy sui rispettivi test set

Per la documentazione dettagliata:

- [docs/data_preparation.md](docs/data_preparation.md)
- [docs/structure_learning.md](docs/structure_learning.md)
- [docs/modeling.md](docs/modeling.md)
- [docs/evaluation.md](docs/evaluation.md)

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
4. Rigenerare, quando necessario, i dataset scenario-specifici AIC/BIC usando gli output della Markov blanket.
5. Addestrare i modelli con gli script in `scripts/modeling/`.
6. Valutare i risultati con gli script in `scripts/evaluation/`.
7. Salvare output, metriche e grafici nelle cartelle `reports/` e nelle relative sottocartelle.

## Script principali

- `scripts/data_preparation/01_load_and_inspect.R`: caricamento del dataset e ispezione iniziale.
- `scripts/data_preparation/02_prepare_data.R`: creazione del dataset preparato, split in `training/validation/test`, costruzione del `full_training_set` e generazione dei dataset ridotti AIC/BIC.
- `scripts/structure_learning/01_learn_dag_hc_aic.R`: confronto di configurazioni `AIC`, selezione del DAG migliore e generazione degli output in `reports/dag/aic/`.
- `scripts/structure_learning/02_learn_dag_hc_bic.R`: confronto di configurazioni `BIC`, selezione del DAG migliore e generazione degli output in `reports/dag/bic/`.
- `scripts/structure_learning/03_export_variable_selection_comparison.R`: creazione del file Excel di confronto tra selezione variabili `AIC` e `BIC`.
- `scripts/modeling/bart/_common.R`: funzioni comuni per validazione e training finale dei modelli BART.
- `scripts/modeling/bart/*/validation.R`: validazione della griglia BART per `no_selection`, `aic_selection` e `bic_selection`.
- `scripts/modeling/bart/*/training.R`: training finale BART usando i migliori parametri salvati dalla validazione.
- `scripts/modeling/naive_bayes/_common.R`: funzioni comuni per training finale dei modelli Naive Bayes.
- `scripts/modeling/naive_bayes/*/training.R`: training diretto Naive Bayes per `no_selection`, `aic_selection` e `bic_selection`.
- `scripts/modeling/tan/_common.R`: funzioni comuni per training finale dei modelli Tree-Augmented Naive Bayes.
- `scripts/modeling/tan/*/training.R`: training diretto TAN per `no_selection`, `aic_selection` e `bic_selection`.
- `scripts/evaluation/bart/_common.R`: funzioni comuni per valutare i model bundle BART sui test set.
- `scripts/evaluation/bart/*/performance.R`: calcolo dell'accuracy di test per i modelli BART finali.
- `scripts/evaluation/naive_bayes/_common.R`: funzioni comuni per valutare i model bundle Naive Bayes sui test set.
- `scripts/evaluation/naive_bayes/*/performance.R`: calcolo dell'accuracy di test per i modelli Naive Bayes finali.
- `scripts/evaluation/tan/_common.R`: funzioni comuni per valutare i model bundle TAN sui test set.
- `scripts/evaluation/tan/*/performance.R`: calcolo dell'accuracy di test per i modelli TAN finali.

## Struttura del progetto

- `.Rprofile`: attiva automaticamente la libreria locale del progetto.
- `project/`: configurazione condivisa del progetto.
  Include `config.R` con i percorsi condivisi del progetto.
- `docs/`: documentazione sintetica delle fasi gia' implementate.
- `data/raw/`: dati originali.
- `data/processed/`: dati puliti o trasformati, inclusi gli split completi e quelli ridotti per selezione AIC/BIC.
- `scripts/data_preparation/`: import, pulizia, feature engineering.
- `scripts/structure_learning/`: apprendimento dei DAG, Markov blanket e confronto AIC/BIC.
- `scripts/modeling/`: training e confronto modelli.
- `scripts/evaluation/`: metriche, grafici e validazione.
- `reports/analisi_esplorativa/`: output dell'analisi esplorativa, incluse figure e file Excel.
- `reports/dag/aic/`: output del DAG appreso con score `AIC`.
- `reports/dag/bic/`: output del DAG appreso con score `BIC`.
- `reports/dag/variable_selection_aic_vs_bic.xlsx`: confronto in Excel della selezione variabili tra `AIC` e `BIC`.
- `reports/modeling/bart/`: risultati di validazione e migliori parametri dei modelli BART.
- `reports/modeling/naive_bayes/`: grafi delle strutture Naive Bayes finali.
- `reports/modeling/tan/`: grafi delle strutture TAN finali.
- `reports/evaluation/bart_evaluation.csv`: confronto finale delle accuracy dei modelli BART sui test set.
- `reports/evaluation/naive_bayes_evaluation.csv`: confronto finale delle accuracy dei modelli Naive Bayes sui test set.
- `reports/evaluation/tan_evaluation.csv`: confronto finale delle accuracy dei modelli TAN sui test set.
- `models/bart/`: modelli BART finali generati localmente. I file `.rds` sono esclusi da Git.
- `models/naive_bayes/`: modelli Naive Bayes finali generati localmente. I file `.rds` sono esclusi da Git.
- `models/tan/`: modelli TAN finali generati localmente. I file `.rds` sono esclusi da Git.
- `ambiente_progettodallavalle/`: libreria locale R esclusa da Git.
