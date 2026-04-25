# Evaluation

## Obiettivo

Questa fase valuta le performance finali dei modelli BART addestrati nella fase di modeling.

La metrica attualmente usata e':

- accuracy sul test set

## Struttura degli script

La logica comune della valutazione BART e' in:

- `scripts/evaluation/bart/_common.R`

Gli script specifici per scenario sono:

- `scripts/evaluation/bart/no_selection/performance.R`
- `scripts/evaluation/bart/aic_selection/performance.R`
- `scripts/evaluation/bart/bic_selection/performance.R`

Il modulo di evaluation e' indipendente dal modulo di modeling: non importa `scripts/modeling/bart/_common.R`, ma legge direttamente i model bundle `.rds` prodotti dal training finale.

## Workflow

Ogni script `performance.R`:

- legge il modello BART finale corretto da `models/bart/`
- legge il test set corretto
- ricostruisce la matrice di test con `model.matrix`
- riallinea le colonne del test set alle `design_columns` salvate nel model bundle
- calcola le predizioni con `predict`
- calcola l'accuracy con soglia `0.5`
- aggiorna il file unico `reports/evaluation/bart_evaluation.csv`

## Script disponibili

Scenario senza selezione:

```r
source("scripts/evaluation/bart/no_selection/performance.R")
```

Scenario AIC:

```r
source("scripts/evaluation/bart/aic_selection/performance.R")
```

Scenario BIC:

```r
source("scripts/evaluation/bart/bic_selection/performance.R")
```

## Input

Modelli:

- `models/bart/no_selection/bart_model_no_selection.rds`
- `models/bart/aic/bart_model_aic.rds`
- `models/bart/bic/bart_model_bic.rds`

Test set:

- `data/processed/no_selection/test_set.csv`
- `data/processed/aic_selection/test_set_aic.csv`
- `data/processed/bic_selection/test_set_bic.csv`

## Output

Il file finale di confronto e':

- `reports/evaluation/bart_evaluation.csv`

Contiene una riga per ciascun modello:

- `no variable selection`
- `aic variable selection`
- `bic variable selection`

Le colonne attuali sono:

- `selection`
- `accuracy`

## Ordine consigliato

1. Eseguire la validazione BART per lo scenario desiderato.
2. Eseguire il training finale BART per lo stesso scenario.
3. Eseguire il relativo script `performance.R`.
4. Ripetere per gli altri scenari.
5. Confrontare le accuracy in `reports/evaluation/bart_evaluation.csv`.
