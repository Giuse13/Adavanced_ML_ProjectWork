from __future__ import annotations

import argparse
import json
import socket
import webbrowser
from datetime import datetime
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from ruota_core import EXCEL_PATH, RuotaData, load_records, matches_preparation_filter


HTML_PAGE = """<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>Interrogatore</title>
  <style>
    :root {
      --bg: #07111f;
      --panel: rgba(16, 25, 45, 0.9);
      --panel-alt: rgba(21, 35, 62, 0.92);
      --border: rgba(118, 151, 199, 0.18);
      --text: #e8f0ff;
      --muted: #9eb0cf;
      --accent: #5eead4;
      --success: #86efac;
      --warning: #fbbf24;
      --danger: #fca5a5;
      --shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
      --radius: 22px;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Trebuchet MS", "Segoe UI", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top left, rgba(20, 184, 166, 0.22), transparent 32%),
        radial-gradient(circle at top right, rgba(251, 191, 36, 0.16), transparent 28%),
        linear-gradient(180deg, #06101d 0%, #0b1830 54%, #09111f 100%);
    }

    .app-shell {
      width: min(1024px, calc(100vw - 24px));
      margin: 0 auto;
      padding: 20px 0 36px;
    }

    .hero {
      padding: 18px 18px 10px;
    }

    .hero h1 {
      margin: 0;
      font-size: clamp(1.9rem, 6vw, 3.1rem);
      line-height: 0.95;
      letter-spacing: -0.04em;
    }

    .hero p {
      margin: 12px 0 0;
      color: var(--muted);
      font-size: 1rem;
      line-height: 1.45;
      max-width: 70ch;
    }

    .panel {
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      backdrop-filter: blur(10px);
    }

    .controls {
      margin-top: 12px;
      padding: 18px;
      background: rgba(12, 47, 95, 0.9);
    }

    .control-fields {
      display: grid;
      grid-template-columns: 1fr;
      gap: 12px;
    }

    .field-group label {
      display: block;
      margin: 0 0 8px;
      color: var(--muted);
      font-size: 0.96rem;
    }

    .filter-checkboxes {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      min-height: 58px;
      padding: 10px 0;
    }

    .filter-option {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 14px;
      border-radius: 14px;
      border: 1px solid var(--border);
      background: rgba(4, 10, 22, 0.55);
      color: var(--text);
      font-size: 0.96rem;
    }

    .filter-option input {
      accent-color: var(--accent);
    }

    input[type="number"],
    select {
      width: 100%;
      min-height: 58px;
      border-radius: 16px;
      border: 1px solid var(--border);
      background: rgba(4, 10, 22, 0.55);
      color: var(--text);
      padding: 0 16px;
      font-size: 1.02rem;
      outline: none;
    }

    input[type="number"]:focus,
    select:focus {
      border-color: var(--accent);
      box-shadow: 0 0 0 3px rgba(94, 234, 212, 0.16);
    }

    .button-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
      margin-top: 24px;
    }

    button {
      min-height: 62px;
      border: 0;
      border-radius: 16px;
      padding: 14px 16px;
      font-size: 1.02rem;
      font-weight: 700;
      cursor: pointer;
      transition: transform 120ms ease, filter 120ms ease, opacity 120ms ease;
    }

    button:active {
      transform: scale(0.985);
    }

    button.primary {
      background: linear-gradient(135deg, var(--accent) 0%, #2dd4bf 100%);
      color: #032221;
    }

    button.secondary {
      background: rgba(18, 37, 65, 0.96);
      color: var(--text);
      border: 1px solid var(--border);
    }

    button.success {
      background: linear-gradient(135deg, #86efac 0%, #22c55e 100%);
      color: #082b13;
    }

    button.warning {
      background: linear-gradient(135deg, #fde68a 0%, #f59e0b 100%);
      color: #382100;
    }

    button:disabled {
      opacity: 0.48;
      cursor: not-allowed;
      filter: grayscale(0.12);
    }

    .card-grid {
      margin-top: 16px;
      display: grid;
      grid-template-columns: 1fr;
      gap: 12px;
    }

    .metric-card {
      padding: 22px;
      min-height: 150px;
      background: rgba(13, 94, 61, 0.92);
      display: flex;
      flex-direction: column;
    }

    .metric-title {
      color: var(--accent);
      font-size: 1rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .metric-value {
      margin-top: 14px;
      font-size: 1.28rem;
      line-height: 1.55;
      word-break: break-word;
      flex: 1;
      display: flex;
      align-items: center;
    }

    .detail-panel {
      margin-top: 16px;
      padding: 18px;
      background: rgba(22, 103, 142, 0.9);
    }

    .detail-panel h2 {
      margin: 0 0 14px;
      font-size: 1.05rem;
      color: var(--muted);
    }

    .prep-editor {
      display: grid;
      grid-template-columns: 1fr;
      gap: 10px;
      margin-top: 24px;
      padding: 14px;
      border-radius: 18px;
      background: rgba(4, 10, 22, 0.45);
      border: 1px solid var(--border);
    }

    .prep-editor label {
      color: var(--muted);
      font-size: 0.96rem;
    }

    .prep-actions {
      display: grid;
      grid-template-columns: 1fr;
      gap: 10px;
    }

    .detail-actions {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
      margin-bottom: 12px;
    }

    .text-editor {
      display: grid;
      grid-template-columns: 1fr;
      gap: 10px;
      margin-top: 12px;
    }

    .detail-box {
      margin-top: 0;
      min-height: 240px;
      padding: 16px;
      border-radius: 18px;
      border: 1px solid var(--border);
      background: rgba(4, 10, 22, 0.65);
      white-space: pre-wrap;
      line-height: 1.55;
    }

    textarea.detail-box {
      width: 100%;
      resize: none;
      color: var(--text);
      font: inherit;
      outline: none;
      overflow-y: hidden;
    }

    textarea.detail-box:focus {
      border-color: var(--accent);
      box-shadow: 0 0 0 3px rgba(94, 234, 212, 0.16);
    }

    .save-text-button {
      min-height: 54px;
      width: 132px;
      padding-left: 10px;
      padding-right: 10px;
      font-size: 0.84rem;
      justify-self: end;
    }

    .footer-note {
      padding: 0 18px;
      margin-top: 16px;
      color: #cfe5ff;
      font-size: 0.92rem;
      line-height: 1.5;
      min-height: 24px;
    }

    @media (min-width: 720px) {
      .control-fields {
        grid-template-columns: minmax(240px, 280px) minmax(220px, 260px);
      }

      .prep-actions {
        grid-template-columns: minmax(180px, 220px) minmax(180px, 220px);
        align-items: end;
      }

      .text-editor {
        grid-template-columns: 1fr auto;
        align-items: stretch;
      }

      .card-grid {
        grid-template-columns: 0.8fr 1.1fr 1.6fr;
      }
    }
  </style>
</head>
<body>
  <main class="app-shell">
    <section class="hero">
      <h1>Interrogatore</h1>
    </section>

    <section class="panel controls">
      <div class="control-fields">
        <div class="field-group">
          <label for="rowInput">Numero domanda</label>
          <input id="rowInput" type="number" inputmode="numeric" min="1" step="1" placeholder="Inserisci numero della domanda">
        </div>
        <div class="field-group">
          <label>Livelli da estrarre</label>
          <div class="filter-checkboxes">
            <label class="filter-option"><input type="checkbox" name="prepFilter" value="1">1</label>
            <label class="filter-option"><input type="checkbox" name="prepFilter" value="2">2</label>
            <label class="filter-option"><input type="checkbox" name="prepFilter" value="3">3</label>
            <label class="filter-option"><input type="checkbox" name="prepFilter" value="4">4</label>
            <label class="filter-option"><input type="checkbox" name="prepFilter" value="5">5</label>
          </div>
        </div>
      </div>

      <div class="button-grid">
        <button id="extractButton" class="primary">Estrai domanda</button>
        <button id="shuffleButton" class="warning">Shuffle OFF</button>
        <button id="previousButton" class="secondary">Previous</button>
        <button id="nextButton" class="secondary">Next</button>
      </div>
    </section>

    <section class="card-grid">
      <article class="panel metric-card">
        <div class="metric-title">Slide</div>
        <div id="slideValue" class="metric-value">In attesa di estrazione</div>
      </article>
      <article class="panel metric-card">
        <div class="metric-title">Argomento</div>
        <div id="argomentoValue" class="metric-value">In attesa di estrazione</div>
      </article>
      <article class="panel metric-card">
        <div class="metric-title">Domanda</div>
        <div id="domandaValue" class="metric-value">In attesa di estrazione</div>
      </article>
    </section>

    <section class="panel detail-panel">
      <h2>Dettagli aggiuntivi</h2>
      <div class="detail-actions">
        <button id="responseButton" class="secondary" disabled>Mostra risposta</button>
        <button id="perCapireButton" class="success" disabled>Mostra Per capire</button>
      </div>
      <div class="text-editor">
        <textarea id="responseBox" class="detail-box" placeholder='Premi "Mostra risposta" per visualizzare o modificare il contenuto.'></textarea>
        <button id="saveResponseButton" class="secondary save-text-button" disabled>Salva risposta</button>
      </div>
      <div class="text-editor">
        <textarea id="perCapireBox" class="detail-box" placeholder='Premi "Mostra Per capire" per visualizzare o modificare il contenuto.'></textarea>
        <button id="savePerCapireButton" class="success save-text-button" disabled>Salva Per capire</button>
      </div>
      <div class="prep-editor">
        <label for="prepSelect">Liv. Preparazione della domanda corrente</label>
        <div class="prep-actions">
          <select id="prepSelect" disabled>
            <option value="">Seleziona livello</option>
            <option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
            <option value="4">4</option>
            <option value="5">5</option>
          </select>
          <button id="savePrepButton" class="success" disabled>Salva livello</button>
        </div>
      </div>
    </section>

    <p id="metaNote" class="footer-note"></p>
  </main>

  <script>
    const state = {
      totalRows: 0,
      currentRow: null,
      currentRecord: null,
      shuffle: false,
      selectedLevels: [],
      responseVisible: false,
      perCapireVisible: false
    };

    const rowInput = document.getElementById("rowInput");
    const filterCheckboxes = Array.from(document.querySelectorAll('input[name="prepFilter"]'));
    const shuffleButton = document.getElementById("shuffleButton");
    const metaNote = document.getElementById("metaNote");
    const slideValue = document.getElementById("slideValue");
    const argomentoValue = document.getElementById("argomentoValue");
    const domandaValue = document.getElementById("domandaValue");
    const responseButton = document.getElementById("responseButton");
    const perCapireButton = document.getElementById("perCapireButton");
    const responseBox = document.getElementById("responseBox");
    const perCapireBox = document.getElementById("perCapireBox");
    const saveResponseButton = document.getElementById("saveResponseButton");
    const savePerCapireButton = document.getElementById("savePerCapireButton");
    const prepSelect = document.getElementById("prepSelect");
    const savePrepButton = document.getElementById("savePrepButton");

    function autoResizeTextarea(textarea) {
      textarea.style.height = "auto";
      textarea.style.height = Math.max(textarea.scrollHeight, 240) + "px";
    }

    function activeFilterDescription() {
      return state.selectedLevels.length === 0
        ? "senza filtro di preparazione"
        : "con livelli " + state.selectedLevels.join(", ");
    }

    function currentRecordMatchesFilter() {
      if (!state.currentRecord || state.selectedLevels.length === 0) {
        return true;
      }
      if (state.currentRecord.preparation_level === null) {
        return false;
      }
      return state.selectedLevels.includes(String(state.currentRecord.preparation_level));
    }

    function updateShuffleUi() {
      shuffleButton.textContent = state.shuffle ? "Shuffle ON" : "Shuffle OFF";
    }

    function syncPreparationEditor() {
      const hasRecord = !!state.currentRecord;
      prepSelect.disabled = !hasRecord;
      savePrepButton.disabled = !hasRecord;
      prepSelect.value = hasRecord && state.currentRecord.preparation_level !== null
        ? String(state.currentRecord.preparation_level)
        : "";
    }

    function syncTextSaveButtons() {
      if (!state.currentRecord) {
        saveResponseButton.disabled = true;
        savePerCapireButton.disabled = true;
        return;
      }

      const hasResponseContent = !!(state.currentRecord.risposta || "");
      const hasPerCapireContent = !!(state.currentRecord.per_capire || "");

      saveResponseButton.disabled = !(state.responseVisible || !hasResponseContent);
      savePerCapireButton.disabled = !(state.perCapireVisible || !hasPerCapireContent);
    }

    function syncPerCapireButton() {
      if (!state.currentRecord) {
        perCapireButton.disabled = true;
        perCapireButton.textContent = "Mostra Per capire";
        return;
      }

      perCapireButton.disabled = !state.currentRecord.has_per_capire;
      perCapireButton.textContent = state.currentRecord.has_per_capire
        ? "Mostra Per capire"
        : "Per capire non disponibile";
    }

    function resetDetailPanels() {
      state.responseVisible = false;
      state.perCapireVisible = false;
      responseBox.value = "";
      perCapireBox.value = "";
      autoResizeTextarea(responseBox);
      autoResizeTextarea(perCapireBox);
      responseButton.textContent = "Mostra risposta";
      responseButton.disabled = !state.currentRecord;
      syncPerCapireButton();
      syncPreparationEditor();
      syncTextSaveButtons();
    }

    function renderRecord(record, statusMessage) {
      state.currentRecord = record;
      state.currentRow = record.row_number;
      rowInput.value = record.row_number;
      slideValue.textContent = record.slide;
      argomentoValue.textContent = record.argomento;
      domandaValue.textContent = record.domanda;
      metaNote.textContent = statusMessage;
      resetDetailPanels();
    }

    function showError(message) {
      metaNote.textContent = message;
      metaNote.style.color = "var(--danger)";
    }

    async function apiRequest(path, options = {}) {
      const response = await fetch(path, options);
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload.error || "Richiesta non riuscita.");
      }
      return payload;
    }

    function filterQuery() {
      return state.selectedLevels.length === 0
        ? ""
        : "&prep_levels=" + encodeURIComponent(state.selectedLevels.join(","));
    }

    async function loadMeta() {
      const payload = await apiRequest("/api/meta");
      state.totalRows = payload.total_rows;
      rowInput.max = payload.total_rows;
      metaNote.textContent = "Domande disponibili: " + payload.total_rows + ". Le domande senza livello salvato rientrano comunque nei filtri per aiutarti a ripassarle.";
      metaNote.style.color = "#cfe5ff";
      updateShuffleUi();
    }

    async function extractRow() {
      metaNote.style.color = "#cfe5ff";
      const rawRow = encodeURIComponent(rowInput.value || "");
      const shuffleValue = state.shuffle ? "1" : "0";
      const payload = await apiRequest("/api/extract?row=" + rawRow + "&shuffle=" + shuffleValue + filterQuery());
      renderRecord(payload.record, payload.status);
    }

    async function navigate(direction) {
      metaNote.style.color = "#cfe5ff";
      const current = state.currentRow === null ? "" : state.currentRow;
      const rawRow = encodeURIComponent(rowInput.value || "");
      const payload = await apiRequest(
        "/api/navigate?direction=" + direction + "&row=" + rawRow + "&current=" + current + filterQuery()
      );
      renderRecord(payload.record, payload.status);
    }

    async function savePreparation() {
      if (!state.currentRecord) {
        return;
      }

      metaNote.style.color = "#cfe5ff";
      if (!prepSelect.value) {
        showError("Seleziona un livello di preparazione tra 1 e 5.");
        return;
      }

      const payload = await apiRequest("/api/preparation", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          row: state.currentRow,
          level: prepSelect.value
        })
      });

      state.currentRecord = payload.record;
      syncPreparationEditor();
      metaNote.textContent = payload.status;

      if (!currentRecordMatchesFilter()) {
        metaNote.textContent += " Nota: questa domanda non rientra piu nel filtro attivo.";
      }
    }

    async function saveTextField(field, value) {
      if (!state.currentRecord) {
        return;
      }

      metaNote.style.color = "#cfe5ff";
      const payload = await apiRequest("/api/text-content", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          row: state.currentRow,
          field,
          text: value
        })
      });

      state.currentRecord = payload.record;
      if (field === "risposta") {
        responseBox.value = payload.record.risposta || "";
        autoResizeTextarea(responseBox);
      } else {
        perCapireBox.value = payload.record.per_capire || "";
        autoResizeTextarea(perCapireBox);
        syncPerCapireButton();
      }
      syncTextSaveButtons();
      metaNote.textContent = payload.status;
    }

    document.getElementById("extractButton").addEventListener("click", async () => {
      try {
        await extractRow();
      } catch (error) {
        showError(error.message);
      }
    });

    document.getElementById("previousButton").addEventListener("click", async () => {
      try {
        await navigate("previous");
      } catch (error) {
        showError(error.message);
      }
    });

    document.getElementById("nextButton").addEventListener("click", async () => {
      try {
        await navigate("next");
      } catch (error) {
        showError(error.message);
      }
    });

    savePrepButton.addEventListener("click", async () => {
      try {
        await savePreparation();
      } catch (error) {
        showError(error.message);
      }
    });

    saveResponseButton.addEventListener("click", async () => {
      try {
        await saveTextField("risposta", responseBox.value);
      } catch (error) {
        showError(error.message);
      }
    });

    savePerCapireButton.addEventListener("click", async () => {
      try {
        await saveTextField("per_capire", perCapireBox.value);
      } catch (error) {
        showError(error.message);
      }
    });

    function toggleShuffle() {
      state.shuffle = !state.shuffle;
      updateShuffleUi();
      metaNote.style.color = "#cfe5ff";
      metaNote.textContent = state.shuffle
        ? "Shuffle attivo: alla prossima estrazione verra usata una domanda casuale " + activeFilterDescription() + "."
        : "Shuffle disattivato: verra usata la domanda inserita " + activeFilterDescription() + ".";
    }

    shuffleButton.addEventListener("click", toggleShuffle);

    filterCheckboxes.forEach((checkbox) => {
      checkbox.addEventListener("change", () => {
        state.selectedLevels = filterCheckboxes
          .filter((item) => item.checked)
          .map((item) => item.value)
          .sort();
        updateShuffleUi();
        metaNote.style.color = "#cfe5ff";
        metaNote.textContent = state.selectedLevels.length === 0
          ? "Filtro disattivato: ora puoi usare tutte le domande."
          : "Filtro attivo: userai solo domande con Liv. Preparazione in [" + state.selectedLevels.join(", ") + "].";
      });
    });

    rowInput.addEventListener("keydown", async (event) => {
      if (event.key !== "Enter") {
        return;
      }

      try {
        await extractRow();
      } catch (error) {
        showError(error.message);
      }
    });

    responseBox.addEventListener("input", () => autoResizeTextarea(responseBox));
    perCapireBox.addEventListener("input", () => autoResizeTextarea(perCapireBox));

    responseButton.addEventListener("click", () => {
      if (!state.currentRecord) {
        return;
      }

      if (state.responseVisible) {
        responseBox.value = "";
        autoResizeTextarea(responseBox);
        responseButton.textContent = "Mostra risposta";
        state.responseVisible = false;
        syncTextSaveButtons();
        return;
      }

      responseBox.value = state.currentRecord.risposta || "";
      autoResizeTextarea(responseBox);
      responseButton.textContent = "Nascondi risposta";
      state.responseVisible = true;
      syncTextSaveButtons();
    });

    perCapireButton.addEventListener("click", () => {
      if (!state.currentRecord) {
        return;
      }

      if (state.perCapireVisible) {
        perCapireBox.value = "";
        autoResizeTextarea(perCapireBox);
        perCapireButton.textContent = "Mostra Per capire";
        state.perCapireVisible = false;
        syncTextSaveButtons();
        return;
      }

      perCapireBox.value = state.currentRecord.per_capire || "";
      autoResizeTextarea(perCapireBox);
      perCapireButton.textContent = "Nascondi Per capire";
      state.perCapireVisible = true;
      syncTextSaveButtons();
    });

    autoResizeTextarea(responseBox);
    autoResizeTextarea(perCapireBox);
    loadMeta().catch((error) => showError(error.message));
  </script>
</body>
</html>
"""


def get_local_ip() -> str:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("8.8.8.8", 80))
        return sock.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        sock.close()


def log_save_event(client_ip: str, message: str) -> None:
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{client_ip}] {message}", flush=True)


class RuotaRequestHandler(BaseHTTPRequestHandler):
    data: RuotaData | None = None

    def do_GET(self) -> None:  # pragma: no cover - exercised by manual use
        parsed = urlparse(self.path)
        if parsed.path == "/":
            self.respond_html(HTML_PAGE)
            return

        if parsed.path == "/api/meta":
            self.respond_json(
                {
                    "total_rows": self.data.total_rows,
                    "excel_path": str(EXCEL_PATH),
                }
            )
            return

        if parsed.path == "/api/extract":
            params = parse_qs(parsed.query)
            raw_row = params.get("row", [""])[0]
            shuffle_active = params.get("shuffle", ["0"])[0] == "1"
            prep_levels = params.get("prep_levels", [""])[0]
            try:
                _row_number, record, status = self.data.extract_row(raw_row, shuffle_active, prep_levels)
            except (ValueError, IndexError) as exc:
                self.respond_error(HTTPStatus.BAD_REQUEST, str(exc))
                return

            self.respond_json({"record": record, "status": status})
            return

        if parsed.path == "/api/navigate":
            params = parse_qs(parsed.query)
            direction = params.get("direction", [""])[0]
            raw_row = params.get("row", [""])[0]
            current_value = params.get("current", [""])[0].strip()
            current_row = int(current_value) if current_value.isdigit() else None
            prep_levels = params.get("prep_levels", [""])[0]

            try:
                if direction == "previous":
                    _row_number, record, status = self.data.go_previous_row(raw_row, current_row, prep_levels)
                elif direction == "next":
                    _row_number, record, status = self.data.go_next_row(raw_row, current_row, prep_levels)
                else:
                    raise ValueError("Direzione di navigazione non valida.")
            except ValueError as exc:
                self.respond_error(HTTPStatus.BAD_REQUEST, str(exc))
                return

            self.respond_json({"record": record, "status": status})
            return

        self.respond_error(HTTPStatus.NOT_FOUND, "Risorsa non trovata.")

    def do_POST(self) -> None:  # pragma: no cover - exercised by manual use
        parsed = urlparse(self.path)
        content_length = int(self.headers.get("Content-Length", "0"))
        try:
            payload = json.loads(self.rfile.read(content_length).decode("utf-8"))
        except json.JSONDecodeError as exc:
            self.respond_error(HTTPStatus.BAD_REQUEST, str(exc))
            return

        try:
            row_number = int(payload.get("row"))
        except (ValueError, TypeError) as exc:
            self.respond_error(HTTPStatus.BAD_REQUEST, "Numero domanda non valido.")
            return

        if parsed.path == "/api/preparation":
            try:
                level = payload.get("level")
                record = self.data.save_preparation_level(row_number, level)
            except ValueError as exc:
                self.respond_error(HTTPStatus.BAD_REQUEST, str(exc))
                return

            level = record.get("preparation_level")
            status = f"Liv. Preparazione salvato per la domanda {row_number}: {level}."
            log_save_event(
                self.client_address[0],
                f"Salvato Liv. Preparazione per domanda {row_number}: livello={level}.",
            )
            self.respond_json({"record": record, "status": status})
            return

        if parsed.path == "/api/text-content":
            try:
                field = payload.get("field")
                text = payload.get("text", "")
                record = self.data.save_text_content(row_number, field, text)
            except ValueError as exc:
                self.respond_error(HTTPStatus.BAD_REQUEST, str(exc))
                return

            field_labels = {
                "risposta": "Risposta",
                "per_capire": "Per capire",
            }
            status = f"{field_labels[field]} salvato per la domanda {row_number}."
            normalized_text = record[field]
            text_length = len(normalized_text)
            action = "svuotato" if not normalized_text else f"salvato ({text_length} caratteri)"
            log_save_event(
                self.client_address[0],
                f"{field_labels[field]} {action} per domanda {row_number}.",
            )
            self.respond_json({"record": record, "status": status})
            return

        self.respond_error(HTTPStatus.NOT_FOUND, "Risorsa non trovata.")

    def log_message(self, format: str, *args) -> None:  # pragma: no cover - keep console clean
        return

    def respond_html(self, content: str) -> None:
        body = content.encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def respond_json(self, payload: dict, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def respond_error(self, status: HTTPStatus, message: str) -> None:
        self.respond_json({"error": message}, status=status)


def create_server(host: str, port: int, data: RuotaData) -> ThreadingHTTPServer:
    handler = type("BoundRuotaRequestHandler", (RuotaRequestHandler,), {"data": data})
    return ThreadingHTTPServer((host, port), handler)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Avvia una versione web dell'Interrogatore, compatibile con tablet Android."
    )
    parser.add_argument("--host", default="0.0.0.0", help="Host su cui esporre il server. Default: 0.0.0.0")
    parser.add_argument("--port", type=int, default=8765, help="Porta HTTP. Default: 8765")
    parser.add_argument(
        "--no-browser",
        action="store_true",
        help="Non aprire automaticamente il browser sul computer locale.",
    )
    return parser.parse_args()


def main() -> None:
    if not EXCEL_PATH.exists():
        raise FileNotFoundError(f"Non trovo il file Excel: {EXCEL_PATH}")

    try:
        records, _dataframe = load_records(EXCEL_PATH)
    except PermissionError as exc:
        raise PermissionError(
            f"Non riesco ad aprire il file Excel:\n{EXCEL_PATH}\n\n"
            "Chiudi Domande.xlsx se e aperto in Excel o in anteprima, poi riprova."
        ) from exc
    data = RuotaData(records, EXCEL_PATH)
    args = parse_args()
    server = create_server(args.host, args.port, data)

    local_url = f"http://127.0.0.1:{args.port}"
    network_url = f"http://{get_local_ip()}:{args.port}"

    print("Interrogatore Web avviato.")
    print(f"Apri sul PC:      {local_url}")
    print(f"Apri sul tablet:  {network_url}")
    print("Per fermare il server premi CTRL+C.")

    if not args.no_browser:
        webbrowser.open(local_url)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\\nServer arrestato.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
