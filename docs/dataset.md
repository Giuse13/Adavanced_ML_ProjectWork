# 📊 Diabetes Health Indicators Dataset (BRFSS 2015)

## 📌 Origine e raccolta del dataset

Il dataset utilizzato deriva dal **Behavioral Risk Factor Surveillance System (BRFSS)**, un’indagine annuale condotta dal **CDC (Centers for Disease Control and Prevention)** negli Stati Uniti. :contentReference[oaicite:0]{index=0}  

Il BRFSS è la più grande indagine telefonica al mondo su salute pubblica e raccoglie informazioni su:
- comportamenti a rischio per la salute  
- condizioni croniche  
- utilizzo dei servizi sanitari :contentReference[oaicite:1]{index=1}  

Nel 2015:
- sono stati raccolti **oltre 400.000 questionari** da tutti gli stati USA :contentReference[oaicite:2]{index=2}  
- i dati includono sia **utenze fisse che cellulari** :contentReference[oaicite:3]{index=3}  

👉 Il dataset Kaggle è una **versione pulita e preprocessata** del BRFSS 2015, pensata per applicazioni di machine learning. :contentReference[oaicite:4]{index=4}  

👉 Il file utilizzato (`diabetes_binary_5050split_health_indicators_BRFSS2015.csv`) contiene:
- circa **70.000 osservazioni**
- **21 variabili esplicative**
- target binario bilanciato (50% diabete / 50% no diabete) :contentReference[oaicite:5]{index=5}  

---

## 🎯 Variabile target

- **Diabetes_binary**
  - 0 = non diabetico  
  - 1 = prediabete o diabete  

---

## 📊 Descrizione delle variabili

### 🩺 Condizioni cliniche
- **HighBP**: presenza di pressione alta  
- **HighChol**: colesterolo alto  
- **CholCheck**: controllo del colesterolo negli ultimi 5 anni  
- **Stroke**: storia di ictus  
- **HeartDiseaseorAttack**: malattie cardiache o infarto  
- **DiffWalk**: difficoltà a camminare o salire scale  

---

### ⚖️ Indicatori fisici
- **BMI**: Body Mass Index (indice di massa corporea)  

---

### 🚬 Stile di vita
- **Smoker**: ha fumato almeno 100 sigarette nella vita  
- **PhysActivity**: attività fisica negli ultimi 30 giorni  
- **Fruits**: consumo giornaliero di frutta  
- **Veggies**: consumo giornaliero di verdura  
- **HvyAlcoholConsump**: consumo eccessivo di alcol  

---

### 🏥 Accesso alla sanità
- **AnyHealthcare**: accesso a copertura sanitaria  
- **NoDocbcCost**: impossibilità di vedere un medico per costi  

---

### 🌡️ Stato di salute percepito
- **GenHlth**: stato di salute generale (scala qualitativa)  
- **MentHlth**: giorni di cattiva salute mentale (ultimi 30 giorni)  
- **PhysHlth**: giorni di cattiva salute fisica (ultimi 30 giorni)  

---

### 🧍 Variabili demografiche
- **Sex**: sesso (0 = donna, 1 = uomo)  
- **Age**: classe di età (categorica)  
- **Education**: livello di istruzione  
- **Income**: livello di reddito  

---

## 🧠 Considerazioni finali

Questo dataset:
- combina **fattori clinici, comportamentali e socio-demografici**
- è particolarmente adatto per:
  - classificazione (diabete sì/no)
  - analisi dei fattori di rischio
  - modelli predittivi in ambito sanitario  

È un tipico esempio di dataset **non invasivo**, basato su questionari, utile per studiare il rischio di diabete senza dati medici diretti (es. glicemia). :contentReference[oaicite:6]{index=6}  

---


| Variable                 | Meaning                                                                | Coding                                                     |
| ------------------------ | ---------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Diabetes_binary**      | Diabetes status                                                        | 0 = no diabetes; 1 = prediabetes or diabetes               |
| **HighBP**               | High blood pressure                                                    | 0 = no; 1 = yes                                            |
| **HighChol**             | High cholesterol                                                       | 0 = no; 1 = yes                                            |
| **CholCheck**            | Cholesterol check in the last 5 years                                  | 0 = no; 1 = yes                                            |
| **BMI**                  | Body Mass Index                                                        | Numeric value                                              |
| **Smoker**               | Smoked at least 100 cigarettes in entire life                          | 0 = no; 1 = yes                                            |
| **Stroke**               | Ever told they had a stroke                                            | 0 = no; 1 = yes                                            |
| **HeartDiseaseorAttack** | Coronary heart disease or myocardial infarction                        | 0 = no; 1 = yes                                            |
| **PhysActivity**         | Physical activity in past 30 days, excluding work                      | 0 = no; 1 = yes                                            |
| **Fruits**               | Consumes fruit one or more times per day                               | 0 = no; 1 = yes                                            |
| **Veggies**              | Consumes vegetables one or more times per day                          | 0 = no; 1 = yes                                            |
| **HvyAlcoholConsump**    | Heavy alcohol consumption                                              | 0 = no; 1 = yes                                            |
| **AnyHealthcare**        | Has any kind of health care coverage                                   | 0 = no; 1 = yes                                            |
| **NoDocbcCost**          | Needed to see a doctor in past 12 months but could not because of cost | 0 = no; 1 = yes                                            |
| **GenHlth**              | Self-rated general health                                              | 1 = excellent; 2 = very good; 3 = good; 4 = fair; 5 = poor |
| **MentHlth**             | Days of poor mental health in past 30 days                             | 0–30 days                                                  |
| **PhysHlth**             | Days of poor physical health in past 30 days                           | 0–30 days                                                  |
| **DiffWalk**             | Serious difficulty walking or climbing stairs                          | 0 = no; 1 = yes                                            |
| **Sex**                  | Sex of respondent                                                      | 0 = female; 1 = male                                       |
| **Age**                  | Age category                                                           | 1 = 18–24; …; 13 = 80+                                     |
| **Education**            |  scale 1-6 1 = Never attended school or only kindergarten 2 = Grades 1 through 8 (Elementary) 3 = Grades 9 through 11 (Some high school) 4 = Grade 12 or GED (High school graduate) 5 = College 1 year to 3 years (Some college or technical school) 6 = College 4 years or more (College graduate)| 1–6 ordinal scale                                          |
| **Income**               | income scale 1-8 1 = less than $10,000 5 = less than $35,000 8 = $75,000 or more                                                           | 1–8 ordinal scale                                          |
