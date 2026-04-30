# Evaluation

## Obiettivo

Questa fase valuta le performance finali dei modelli BART, Neural Network, Naive Bayes e TAN addestrati nella fase di modeling.

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

La logica comune della valutazione Neural Network e' in:

- `scripts/evaluation/neural_network/_common.R`

Gli script Neural Network specifici per scenario sono:

- `scripts/evaluation/neural_network/no_selection/performance.R`
- `scripts/evaluation/neural_network/aic_selection/performance.R`
- `scripts/evaluation/neural_network/bic_selection/performance.R`

Lo script di aggregazione finale e':

- `scripts/evaluation/merge_model_performances.R`

I moduli di evaluation sono indipendenti dai moduli di modeling: leggono direttamente i model bundle prodotti dal training finale. Per le reti neurali, il bundle `.rds` contiene metadati, scaler e path del modello, mentre il modello `luz` vero e proprio viene ricaricato dal file `.luz`.

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

Ogni script Neural Network `performance.R`:

- legge il bundle Neural Network finale corretto da `models/neural_network/`
- legge il test set corretto
- ricostruisce la matrice di test con `model.matrix`
- riallinea le colonne del test set alle `design_columns` salvate nel model bundle
- applica lo scaler salvato nel model bundle
- ricarica il modello `luz`
- calcola le probabilita' predette
- calcola l'accuracy con soglia `0.5`
- aggiorna il file unico definito in `project/config.R`: `reports/evaluation/neural_network_evaluation.csv`

Lo script `merge_model_performances.R`:

- legge i CSV finali di BART, Neural Network, Naive Bayes e TAN
- fonde le accuracy in formato wide
- salva `reports/evaluation/model_comparison_evaluation.csv`, con righe = modello e colonne = scenario di selezione variabili

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

## Script disponibili Neural Network

Scenario senza selezione:

```r
source("scripts/evaluation/neural_network/no_selection/performance.R")
```

Scenario AIC:

```r
source("scripts/evaluation/neural_network/aic_selection/performance.R")
```

Scenario BIC:

```r
source("scripts/evaluation/neural_network/bic_selection/performance.R")
```

## Script di confronto finale

```r
source("scripts/evaluation/merge_model_performances.R")
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

Modelli Neural Network:

- `models/neural_network/no_selection/neural_network_model_no_selection.rds`
- `models/neural_network/no_selection/neural_network_model_no_selection.rds.luz`
- `models/neural_network/aic/neural_network_model_aic.rds`
- `models/neural_network/aic/neural_network_model_aic.rds.luz`
- `models/neural_network/bic/neural_network_model_bic.rds`
- `models/neural_network/bic/neural_network_model_bic.rds.luz`

Test set:

- `data/processed/no_selection/test_set.csv`
- `data/processed/aic_selection/test_set_aic.csv`
- `data/processed/bic_selection/test_set_bic.csv`

## Output

I file finali di confronto sono:

- `reports/evaluation/bart_evaluation.csv`
- `reports/evaluation/neural_network_evaluation.csv`
- `reports/evaluation/naive_bayes_evaluation.csv`
- `reports/evaluation/tan_evaluation.csv`
- `reports/evaluation/model_comparison_evaluation.csv`

I primi quattro file contengono una riga per ciascuno scenario:

- `no variable selection`
- `aic variable selection`
- `bic variable selection`

Le colonne attuali sono:

- `selection`
- `accuracy`

Il file aggregato `model_comparison_evaluation.csv` contiene invece:

- `model`
- `no variable selection`
- `aic variable selection`
- `bic variable selection`

## Risultati attuali

Le accuracy attualmente salvate nei file di evaluation sono:

| Modello | No selection | AIC selection | BIC selection |
| --- | ---: | ---: | ---: |
| BART | 0.7501 | 0.7502 | 0.7498 |
| Neural Network | 0.7529 | 0.7506 | 0.7522 |
| Naive Bayes | 0.7306 | 0.7402 | 0.7405 |
| TAN | 0.7423 | 0.7441 | 0.7390 |

## Ordine consigliato

1. Eseguire la validazione BART per lo scenario desiderato.
2. Eseguire il training finale BART per lo stesso scenario.
3. Eseguire la validazione Neural Network per lo scenario desiderato.
4. Eseguire il training finale Neural Network per lo stesso scenario.
5. Eseguire il training finale Naive Bayes per lo scenario desiderato.
6. Eseguire il training finale TAN per lo scenario desiderato.
7. Eseguire i relativi script `performance.R`.
8. Ripetere per gli altri scenari.
9. Eseguire `scripts/evaluation/merge_model_performances.R`.
10. Confrontare le accuracy in `reports/evaluation/model_comparison_evaluation.csv`.
