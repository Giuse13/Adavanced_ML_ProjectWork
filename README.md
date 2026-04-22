# Adavanced_ML_ProjectWork

Questo repository e' organizzato per un progetto di machine learning in R: analisi dei dati, preparazione del dataset, addestramento dei modelli e valutazione finale.

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
3. Addestrare i modelli con gli script in `scripts/modeling/`.
4. Valutare i risultati con gli script in `scripts/evaluation/`.
5. Salvare output, metriche e grafici nelle cartelle `models/`, `reports/analisi_esplorativa/` e `reports/results/`.

## Struttura del progetto

- `.Rprofile`: attiva automaticamente la libreria locale del progetto.
- `project/`: configurazione condivisa del progetto.
  Include `config.R` con i percorsi condivisi del progetto.
- `data/raw/`: dati originali.
- `data/processed/`: dati puliti o trasformati.
- `scripts/data_preparation/`: import, pulizia, feature engineering.
- `scripts/modeling/`: training e confronto modelli.
- `scripts/evaluation/`: metriche, grafici e validazione.
- `scripts/utils/`: funzioni riutilizzabili.
- `models/`: modelli salvati.
- `reports/analisi_esplorativa/`: output dell'analisi esplorativa, incluse figure e file Excel.
- `reports/results/`: tabelle, metriche e output finali.
- `ambiente_progettodallavalle/`: libreria locale R esclusa da Git.
