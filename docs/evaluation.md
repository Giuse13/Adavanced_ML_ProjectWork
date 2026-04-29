# Evaluation

## Obiettivo

Questa fase valuta le performance finali dei modelli BART, Naive Bayes e TAN addestrati nella fase di modeling.

La metrica attualmente usata e':

- accuracy sul test set

## Struttura degli script

La logica comune della valutazione BART e' in:

- `scripts/evaluation/bart/_common.R`

Gli script BART specifici per scenario sono:

- `scripts/evaluation/bart/no_selection/performance.R`
- `scripts/evaluation/bart/aic_selection/performance.R`
- `scripts/evaluation/bart/bic_selection/performance.R`

La logica comune della valutazione Naive Bayes e' in:

- `scripts/evaluation/naive_bayes/_common.R`

Gli script Naive Bayes specifici per scenario sono:

- `scripts/evaluation/naive_bayes/no_selection/performance.R`
- `scripts/evaluation/naive_bayes/aic_selection/performance.R`
- `scripts/evaluation/naive_bayes/bic_selection/performance.R`

La logica comune della valutazione TAN e' in:

- `scripts/evaluation/tan/_common.R`

Gli script TAN specifici per scenario sono:

- `scripts/evaluation/tan/no_selection/performance.R`
- `scripts/evaluation/tan/aic_selection/performance.R`
- `scripts/evaluation/tan/bic_selection/performance.R`

I moduli di evaluation sono indipendenti dai moduli di modeling: leggono direttamente i model bundle `.rds` prodotti dal training finale.

## Workflow

Ogni script BART `performance.R`:

- legge il modello BART finale corretto da `models/bart/`
- legge il test set corretto
- ricostruisce la matrice di test con `model.matrix`
- riallinea le colonne del test set alle `design_columns` salvate nel model bundle
- calcola le predizioni con `predict`
- calcola l'accuracy con soglia `0.5`
- aggiorna il file unico definito in `project/config.R`: `reports/evaluation/bart_evaluation.csv`

Ogni script Naive Bayes `performance.R`:

- legge il modello Naive Bayes finale corretto da `models/naive_bayes/`
- legge il test set corretto
- riallinea i factor ai livelli salvati nel model bundle
- calcola le predizioni con `predict`
- calcola l'accuracy
- aggiorna il file unico definito in `project/config.R`: `reports/evaluation/naive_bayes_evaluation.csv`

Ogni script TAN `performance.R`:

- legge il modello TAN finale corretto da `models/tan/`
- legge il test set corretto
- riallinea i factor ai livelli salvati nel model bundle
- calcola le predizioni con `predict`
- calcola l'accuracy
- aggiorna il file unico definito in `project/config.R`: `reports/evaluation/tan_evaluation.csv`

## Script disponibili BART

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

## Script disponibili Naive Bayes

Scenario senza selezione:

```r
source("scripts/evaluation/naive_bayes/no_selection/performance.R")
```

Scenario AIC:

```r
source("scripts/evaluation/naive_bayes/aic_selection/performance.R")
```

Scenario BIC:

```r
source("scripts/evaluation/naive_bayes/bic_selection/performance.R")
```

## Script disponibili TAN

Scenario senza selezione:

```r
source("scripts/evaluation/tan/no_selection/performance.R")
```

Scenario AIC:

```r
source("scripts/evaluation/tan/aic_selection/performance.R")
```

Scenario BIC:

```r
source("scripts/evaluation/tan/bic_selection/performance.R")
```

## Input

Modelli BART:

- `models/bart/no_selection/bart_model_no_selection.rds`
- `models/bart/aic/bart_model_aic.rds`
- `models/bart/bic/bart_model_bic.rds`

Modelli Naive Bayes:

- `models/naive_bayes/no_selection/naive_bayes_model_no_selection.rds`
- `models/naive_bayes/aic/naive_bayes_model_aic.rds`
- `models/naive_bayes/bic/naive_bayes_model_bic.rds`

Modelli TAN:

- `models/tan/no_selection/tan_model_no_selection.rds`
- `models/tan/aic/tan_model_aic.rds`
- `models/tan/bic/tan_model_bic.rds`

Test set:

- `data/processed/no_selection/test_set.csv`
- `data/processed/aic_selection/test_set_aic.csv`
- `data/processed/bic_selection/test_set_bic.csv`

## Output

I file finali di confronto sono:

- `reports/evaluation/bart_evaluation.csv`
- `reports/evaluation/naive_bayes_evaluation.csv`
- `reports/evaluation/tan_evaluation.csv`

Ogni file contiene una riga per ciascuno scenario:

- `no variable selection`
- `aic variable selection`
- `bic variable selection`

Le colonne attuali sono:

- `selection`
- `accuracy`

## Risultati attuali

Le accuracy attualmente salvate nei file di evaluation sono:

| Modello | No selection | AIC selection | BIC selection |
| --- | ---: | ---: | ---: |
| BART | 0.7501 | 0.7502 | 0.7498 |
| Naive Bayes | 0.7306 | 0.7402 | 0.7405 |
| TAN | 0.7423 | 0.7441 | 0.7390 |

## Ordine consigliato

1. Eseguire la validazione BART per lo scenario desiderato.
2. Eseguire il training finale BART per lo stesso scenario.
3. Eseguire il training finale Naive Bayes per lo scenario desiderato.
4. Eseguire il training finale TAN per lo scenario desiderato.
5. Eseguire i relativi script `performance.R`.
6. Ripetere per gli altri scenari.
7. Confrontare le accuracy in `reports/evaluation/bart_evaluation.csv`, `reports/evaluation/naive_bayes_evaluation.csv` e `reports/evaluation/tan_evaluation.csv`.
