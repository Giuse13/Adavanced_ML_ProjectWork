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