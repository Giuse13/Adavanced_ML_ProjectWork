from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, scrolledtext, ttk
from ruota_core import EXCEL_PATH, RuotaData, format_value, is_empty, load_records


class RuotaDellaFortunaGUI:
    def __init__(self, root: tk.Tk, records: list[dict]):
        self.root = root
        self.data = RuotaData(records)
        self.records = self.data.records
        self.current_record: dict | None = None
        self.current_row_number: int | None = None
        self.response_visible = False
        self.per_capire_visible = False
        self.shuffle_enabled = tk.BooleanVar(value=False)
        self.preparation_filter_vars = {
            level: tk.BooleanVar(value=False)
            for level in range(1, 6)
        }
        self.preparation_value_var = tk.StringVar(value="")
        self.slide_col = self.data.slide_col
        self.argomento_col = self.data.argomento_col
        self.domanda_col = self.data.domanda_col
        self.risposta_col = self.data.risposta_col
        self.per_capire_col = self.data.per_capire_col
        self.preparation_col = self.data.preparation_col

        self.palette = {
            "bg": "#0b1120",
            "panel": "#111827",
            "panel_alt": "#172033",
            "text": "#e5eefc",
            "muted": "#95a3bd",
            "accent": "#38bdf8",
            "accent_hover": "#7dd3fc",
            "accent_soft": "#0f3b5a",
            "green": "#22c55e",
            "green_hover": "#16a34a",
            "disabled": "#334155",
            "border": "#243041",
            "editor": "#0f172a",
            "warning": "#f59e0b",
        }

        self.build_ui()

    def build_ui(self) -> None:
        self.root.title("Ruota della Fortuna - Dark Mode")
        self.root.geometry("1080x760")
        self.root.minsize(900, 650)
        self.root.configure(bg=self.palette["bg"])

        style = ttk.Style()
        style.theme_use("clam")
        style.configure("Shell.TFrame", background=self.palette["bg"])
        style.configure("Card.TFrame", background=self.palette["panel"])
        style.configure("Inner.TFrame", background=self.palette["panel"])
        style.configure(
            "Title.TLabel",
            font=("Segoe UI", 20, "bold"),
            background=self.palette["bg"],
            foreground=self.palette["text"],
        )
        style.configure(
            "Hint.TLabel",
            font=("Segoe UI", 10),
            background=self.palette["bg"],
            foreground=self.palette["muted"],
        )
        style.configure(
            "CardTitle.TLabel",
            font=("Segoe UI", 12, "bold"),
            background=self.palette["panel"],
            foreground=self.palette["text"],
        )
        style.configure(
            "MetricLabel.TLabel",
            font=("Segoe UI", 10, "bold"),
            background=self.palette["panel_alt"],
            foreground=self.palette["accent"],
        )
        style.configure(
            "MetricValue.TLabel",
            font=("Segoe UI", 13),
            background=self.palette["panel_alt"],
            foreground=self.palette["text"],
        )
        style.configure(
            "Section.TLabelframe",
            background=self.palette["panel"],
            bordercolor=self.palette["border"],
            relief="solid",
        )
        style.configure(
            "Section.TLabelframe.Label",
            background=self.palette["panel"],
            foreground=self.palette["accent"],
            font=("Segoe UI", 11, "bold"),
        )
        style.configure(
            "Dark.TEntry",
            fieldbackground=self.palette["editor"],
            foreground=self.palette["text"],
            bordercolor=self.palette["border"],
            insertcolor=self.palette["accent"],
            padding=8,
        )
        style.map("Dark.TEntry", bordercolor=[("focus", self.palette["accent"])])
        style.configure(
            "Dark.TCombobox",
            fieldbackground=self.palette["editor"],
            background=self.palette["editor"],
            foreground=self.palette["text"],
            arrowcolor=self.palette["accent"],
            bordercolor=self.palette["border"],
            padding=6,
        )
        style.map("Dark.TCombobox", bordercolor=[("focus", self.palette["accent"])])
        style.configure(
            "Accent.TButton",
            font=("Segoe UI", 10, "bold"),
            padding=(14, 10),
            background=self.palette["accent"],
            foreground="#08111d",
            borderwidth=0,
        )
        style.map(
            "Accent.TButton",
            background=[("active", self.palette["accent_hover"]), ("disabled", self.palette["disabled"])],
            foreground=[("disabled", "#64748b")],
        )
        style.configure(
            "Ghost.TButton",
            font=("Segoe UI", 10, "bold"),
            padding=(14, 10),
            background=self.palette["accent_soft"],
            foreground=self.palette["text"],
            borderwidth=0,
        )
        style.map(
            "Ghost.TButton",
            background=[("active", "#14547e"), ("disabled", self.palette["disabled"])],
            foreground=[("disabled", "#64748b")],
        )

        main_container = ttk.Frame(self.root, style="Shell.TFrame")
        main_container.pack(fill="both", expand=True)

        self.main_canvas = tk.Canvas(
            main_container,
            bg=self.palette["bg"],
            highlightthickness=0,
            bd=0,
        )
        self.main_canvas.pack(side="left", fill="both", expand=True)

        self.main_scrollbar = ttk.Scrollbar(
            main_container,
            orient="vertical",
            command=self.main_canvas.yview,
        )
        self.main_scrollbar.pack(side="right", fill="y")

        self.main_canvas.configure(yscrollcommand=self.main_scrollbar.set)

        outer = ttk.Frame(self.main_canvas, padding=22, style="Shell.TFrame")
        self.canvas_window_id = self.main_canvas.create_window((0, 0), window=outer, anchor="nw")
        outer.bind("<Configure>", self.on_content_configure)
        self.main_canvas.bind("<Configure>", self.on_canvas_configure)
        self.main_canvas.bind_all("<MouseWheel>", self.on_mousewheel)

        ttk.Label(outer, text="Ruota della Fortuna", style="Title.TLabel").pack(anchor="w")
        ttk.Label(
            outer,
            text=(
                f"Inserisci una domanda tra 1 e {len(self.records)}. "
                "Puoi anche filtrare per Liv. Preparazione e salvare il livello direttamente nel file Excel."
            ),
            style="Hint.TLabel",
        ).pack(anchor="w", pady=(4, 14))

        top_card = ttk.Frame(outer, style="Card.TFrame", padding=16)
        top_card.pack(fill="x")

        input_row = ttk.Frame(top_card, style="Inner.TFrame")
        input_row.pack(fill="x")

        ttk.Label(input_row, text="Domanda:", style="CardTitle.TLabel").pack(side="left")
        self.row_entry = ttk.Entry(input_row, width=12, style="Dark.TEntry")
        self.row_entry.pack(side="left", padx=(10, 10))
        self.row_entry.bind("<Return>", self.extract_row)

        self.extract_button = ttk.Button(
            input_row,
            text="Estrai domanda",
            command=self.extract_row,
            style="Accent.TButton",
        )
        self.extract_button.pack(side="left")

        self.shuffle_button = tk.Button(
            input_row,
            text="Shuffle OFF",
            command=self.toggle_shuffle,
            bg=self.palette["panel_alt"],
            fg=self.palette["text"],
            activebackground="#1e293b",
            activeforeground=self.palette["text"],
            relief="flat",
            bd=0,
            padx=16,
            pady=9,
            cursor="hand2",
        )
        self.shuffle_button.pack(side="left", padx=(12, 0))

        self.previous_button = ttk.Button(
            input_row,
            text="Previous",
            command=self.go_previous_row,
            style="Ghost.TButton",
        )
        self.previous_button.pack(side="left", padx=(12, 0))

        self.next_button = ttk.Button(
            input_row,
            text="Next",
            command=self.go_next_row,
            style="Ghost.TButton",
        )
        self.next_button.pack(side="left", padx=(12, 0))

        filter_row = ttk.Frame(top_card, style="Inner.TFrame")
        filter_row.pack(fill="x", pady=(12, 0))

        ttk.Label(filter_row, text="Livelli da estrarre:", style="CardTitle.TLabel").pack(side="left")
        checkbox_row = ttk.Frame(filter_row, style="Inner.TFrame")
        checkbox_row.pack(side="left", padx=(10, 10))

        for level, variable in self.preparation_filter_vars.items():
            tk.Checkbutton(
                checkbox_row,
                text=str(level),
                variable=variable,
                command=self.on_preparation_filter_changed,
                bg=self.palette["panel"],
                fg=self.palette["text"],
                activebackground=self.palette["panel"],
                activeforeground=self.palette["text"],
                selectcolor=self.palette["editor"],
                highlightthickness=0,
                bd=0,
                padx=6,
            ).pack(side="left")

        ttk.Label(
            filter_row,
            text="Se non selezioni nulla, verranno usate tutte le domande.",
            style="Hint.TLabel",
        ).pack(side="left")

        self.status_var = tk.StringVar(value="Nessuna domanda selezionata.")
        ttk.Label(top_card, textvariable=self.status_var, style="Hint.TLabel").pack(anchor="w", pady=(10, 0))

        summary_card = ttk.Frame(outer, style="Card.TFrame", padding=16)
        summary_card.pack(fill="x", pady=(16, 0))

        ttk.Label(summary_card, text="Contenuto principale", style="CardTitle.TLabel").pack(anchor="w")
        self.cards_row = ttk.Frame(summary_card, style="Inner.TFrame")
        self.cards_row.pack(fill="x", pady=(12, 0))
        self.cards_row.columnconfigure(0, weight=1)
        self.cards_row.columnconfigure(1, weight=1)
        self.cards_row.columnconfigure(2, weight=2)

        self.slide_value_var = tk.StringVar(value="In attesa di estrazione")
        self.argomento_value_var = tk.StringVar(value="In attesa di estrazione")
        self.domanda_value_var = tk.StringVar(value="In attesa di estrazione")

        self.create_info_card(self.cards_row, 0, "Slide", self.slide_value_var, 180)
        self.create_info_card(self.cards_row, 1, "Argomento", self.argomento_value_var, 220)
        self.create_info_card(self.cards_row, 2, "Domanda", self.domanda_value_var, 360)

        preparation_card = ttk.Frame(outer, style="Card.TFrame", padding=16)
        preparation_card.pack(fill="x", pady=(16, 0))

        ttk.Label(preparation_card, text="Liv. Preparazione", style="CardTitle.TLabel").pack(anchor="w")
        preparation_row = ttk.Frame(preparation_card, style="Inner.TFrame")
        preparation_row.pack(fill="x", pady=(12, 0))

        self.preparation_value_box = ttk.Combobox(
            preparation_row,
            textvariable=self.preparation_value_var,
            values=["1", "2", "3", "4", "5"],
            state="readonly",
            width=8,
            style="Dark.TCombobox",
        )
        self.preparation_value_box.pack(side="left")

        self.save_preparation_button = ttk.Button(
            preparation_row,
            text="Salva livello",
            command=self.save_preparation_level,
            state="disabled",
            style="Accent.TButton",
        )
        self.save_preparation_button.pack(side="left", padx=(12, 0))

        ttk.Label(
            preparation_row,
            text="Aggiorna il valore 1-5 per la domanda corrente e salvalo sul file Excel.",
            style="Hint.TLabel",
        ).pack(side="left", padx=(12, 0))

        actions = ttk.Frame(outer, style="Shell.TFrame")
        actions.pack(fill="x", pady=(16, 0))

        self.response_button = ttk.Button(
            actions,
            text="Salva risposta",
            command=self.save_response_content,
            state="disabled",
            style="Ghost.TButton",
        )
        self.response_button.pack(side="left")

        self.per_capire_button = tk.Button(
            actions,
            text="Salva Per capire",
            command=self.save_per_capire_content,
            state="disabled",
            bg=self.palette["disabled"],
            fg=self.palette["muted"],
            activebackground=self.palette["disabled"],
            activeforeground=self.palette["muted"],
            relief="flat",
            bd=0,
            padx=14,
            pady=10,
        )
        self.per_capire_button.pack(side="left", padx=(12, 0))

        detail_card = ttk.Frame(outer, style="Card.TFrame", padding=16)
        detail_card.pack(fill="both", expand=True, pady=(16, 0))

        ttk.Label(detail_card, text="Dettagli aggiuntivi", style="CardTitle.TLabel").pack(anchor="w")

        response_frame = ttk.LabelFrame(detail_card, text="Risposta", padding=10, style="Section.TLabelframe")
        response_frame.pack(fill="both", expand=True, pady=(12, 10))
        self.response_box = self.create_text_box(response_frame, height=8, font=("Segoe UI", 15))
        self.response_box.pack(fill="both", expand=True)
        self.set_editor_text(self.response_box, "")

        per_capire_frame = ttk.LabelFrame(detail_card, text="Per capire", padding=10, style="Section.TLabelframe")
        per_capire_frame.pack(fill="both", expand=True)
        self.per_capire_box = self.create_text_box(per_capire_frame, height=8, font=("Segoe UI", 15))
        self.per_capire_box.pack(fill="both", expand=True)
        self.set_editor_text(self.per_capire_box, "")

        self.update_shuffle_button()

    def on_content_configure(self, _event=None) -> None:
        self.main_canvas.configure(scrollregion=self.main_canvas.bbox("all"))

    def on_canvas_configure(self, event) -> None:
        self.main_canvas.itemconfigure(self.canvas_window_id, width=event.width)

    def on_mousewheel(self, event) -> None:
        if not hasattr(self, "main_canvas"):
            return
        self.main_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")

    def create_text_box(self, parent, height: int, font) -> scrolledtext.ScrolledText:
        return scrolledtext.ScrolledText(
            parent,
            height=height,
            wrap="word",
            font=font,
            padx=10,
            pady=10,
            bg=self.palette["editor"],
            fg=self.palette["text"],
            insertbackground=self.palette["accent"],
            selectbackground="#1d4ed8",
            relief="flat",
            bd=0,
        )

    def create_info_card(
        self,
        parent,
        column: int,
        title: str,
        value_var: tk.StringVar,
        wraplength: int,
    ) -> None:
        card = tk.Frame(
            parent,
            bg=self.palette["panel_alt"],
            bd=1,
            highlightthickness=1,
            highlightbackground=self.palette["border"],
            padx=16,
            pady=16,
        )
        card.grid(row=0, column=column, sticky="nsew", padx=(0, 12) if column < 2 else (0, 0))

        title_label = ttk.Label(card, text=title, style="MetricLabel.TLabel")
        title_label.pack(anchor="w")

        value_label = ttk.Label(
            card,
            textvariable=value_var,
            style="MetricValue.TLabel",
            wraplength=wraplength,
            justify="left",
        )
        value_label.pack(anchor="w", fill="x", pady=(12, 0))

    def update_main_cards(self, record: dict | None = None) -> None:
        if record is None:
            self.slide_value_var.set("In attesa di estrazione")
            self.argomento_value_var.set("In attesa di estrazione")
            self.domanda_value_var.set("In attesa di estrazione")
            self.preparation_value_var.set("")
            self.save_preparation_button.configure(state="disabled")
            return

        self.slide_value_var.set(format_value(record[self.slide_col]) or "-")
        self.argomento_value_var.set(format_value(record[self.argomento_col]) or "-")
        self.domanda_value_var.set(format_value(record[self.domanda_col]) or "-")

    def set_text(self, widget: scrolledtext.ScrolledText, text: str) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", tk.END)
        widget.insert("1.0", text)
        widget.configure(state="disabled")

    def set_editor_text(self, widget: scrolledtext.ScrolledText, text: str) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", tk.END)
        widget.insert("1.0", text)

    def get_editor_text(self, widget: scrolledtext.ScrolledText) -> str:
        return widget.get("1.0", tk.END).replace("\r\n", "\n").rstrip("\n")

    def set_row_entry_value(self, row_number: int) -> None:
        self.row_entry.delete(0, tk.END)
        self.row_entry.insert(0, str(row_number))

    def get_record_by_row(self, row_number: int) -> dict:
        return self.data.get_record_by_row(row_number)

    def get_preparation_filter_value(self) -> list[int] | None:
        selected_levels = [
            level
            for level, variable in self.preparation_filter_vars.items()
            if variable.get()
        ]
        return selected_levels or None

    def on_preparation_filter_changed(self, _event=None) -> None:
        filter_values = self.get_preparation_filter_value()
        if filter_values is None:
            self.status_var.set("Filtro preparazione disattivato: ora puoi usare tutte le domande.")
            return

        selected_levels = ", ".join(str(level) for level in filter_values)
        self.status_var.set(
            f"Filtro attivo: verranno usate solo domande con Liv. Preparazione in [{selected_levels}]."
        )

    def update_preparation_controls(self, record: dict | None = None) -> None:
        if record is None:
            self.preparation_value_var.set("")
            self.save_preparation_button.configure(state="disabled")
            return

        preparation_level = self.data.get_preparation_level(record)
        self.preparation_value_var.set("" if preparation_level is None else str(preparation_level))
        self.save_preparation_button.configure(state="normal")

    def show_record(self, row_number: int, status_message: str) -> None:
        record = self.get_record_by_row(row_number)
        self.current_record = record
        self.current_row_number = row_number
        self.response_visible = False
        self.per_capire_visible = False

        self.set_row_entry_value(row_number)
        self.update_main_cards(record)
        self.update_preparation_controls(record)
        self.set_editor_text(self.response_box, format_value(record.get(self.risposta_col, "")))
        self.set_editor_text(self.per_capire_box, format_value(record.get(self.per_capire_col, "")))
        self.response_button.configure(state="normal", text="Salva risposta")

        per_capire_value = record.get(self.per_capire_col, "")
        self.per_capire_button.configure(
            state="normal",
            text="Salva Per capire",
            bg=self.palette["green"],
            fg="#052e16",
            activebackground=self.palette["green_hover"],
            activeforeground="#052e16",
        )

        self.status_var.set(status_message)

    def update_shuffle_button(self) -> None:
        if self.shuffle_enabled.get():
            self.shuffle_button.configure(
                text="Shuffle ON",
                bg=self.palette["warning"],
                fg="#1a1203",
                activebackground="#fbbf24",
                activeforeground="#1a1203",
            )
        else:
            self.shuffle_button.configure(
                text="Shuffle OFF",
                bg=self.palette["panel_alt"],
                fg=self.palette["text"],
                activebackground="#1e293b",
                activeforeground=self.palette["text"],
            )

    def toggle_shuffle(self) -> None:
        self.shuffle_enabled.set(not self.shuffle_enabled.get())
        self.update_shuffle_button()
        filter_value = self.get_preparation_filter_value()
        if filter_value is None:
            filter_suffix = ""
        else:
            selected_levels = ", ".join(str(level) for level in filter_value)
            filter_suffix = f" con Liv. Preparazione in [{selected_levels}]"
        if self.shuffle_enabled.get():
            self.status_var.set(
                f"Shuffle attivo: alla prossima estrazione verra usata una domanda casuale{filter_suffix}."
            )
        else:
            self.status_var.set(f"Shuffle disattivato: verra usata la domanda inserita{filter_suffix}.")

    def get_navigation_base_row(self) -> int:
        return self.data.get_navigation_base_row(
            self.row_entry.get(),
            self.current_row_number,
            self.get_preparation_filter_value(),
        )

    def go_previous_row(self) -> None:
        try:
            row_number, _record, status_message = self.data.go_previous_row(
                self.row_entry.get(),
                self.current_row_number,
                self.get_preparation_filter_value(),
            )
        except ValueError as exc:
            messagebox.showwarning("Filtro non valido", str(exc))
            return
        self.show_record(row_number, status_message)

    def go_next_row(self) -> None:
        try:
            row_number, _record, status_message = self.data.go_next_row(
                self.row_entry.get(),
                self.current_row_number,
                self.get_preparation_filter_value(),
            )
        except ValueError as exc:
            messagebox.showwarning("Filtro non valido", str(exc))
            return
        self.show_record(row_number, status_message)

    def extract_row(self, _event=None) -> None:
        try:
            row_number, _record, status_message = self.data.extract_row(
                self.row_entry.get(),
                self.shuffle_enabled.get(),
                self.get_preparation_filter_value(),
            )
        except ValueError as exc:
            messagebox.showwarning("Input non valido", str(exc))
            return
        except IndexError:
            messagebox.showwarning(
                "Domanda fuori intervallo",
                f"Inserisci una domanda tra 1 e {len(self.records)}.",
            )
            return

        self.show_record(row_number, status_message)

    def save_preparation_level(self) -> None:
        if self.current_row_number is None:
            messagebox.showwarning("Nessuna domanda", "Estrai prima una domanda.")
            return

        if not self.preparation_value_var.get().strip():
            messagebox.showwarning("Livello mancante", "Seleziona un livello di preparazione tra 1 e 5.")
            return

        try:
            updated_record = self.data.save_preparation_level(
                self.current_row_number,
                self.preparation_value_var.get(),
            )
        except ValueError as exc:
            messagebox.showwarning("Salvataggio non riuscito", str(exc))
            return

        self.current_record = self.get_record_by_row(self.current_row_number)
        self.update_preparation_controls(self.current_record)

        status_message = (
            f"Liv. Preparazione salvato per la domanda {self.current_row_number}: "
            f"{updated_record['preparation_level']}."
        )
        filter_value = self.get_preparation_filter_value()
        if filter_value is not None:
            try:
                self.data.ensure_row_matches_filter(self.current_row_number, filter_value)
            except ValueError:
                status_message += " Nota: questa domanda non rientra piu nel filtro attivo."

        self.status_var.set(status_message)

    def save_response_content(self) -> None:
        if self.current_record is None:
            messagebox.showwarning("Nessuna domanda", "Estrai prima una domanda.")
            return

        try:
            updated_record = self.data.save_text_content(
                self.current_row_number,
                "risposta",
                self.get_editor_text(self.response_box),
            )
        except ValueError as exc:
            messagebox.showwarning("Salvataggio non riuscito", str(exc))
            return

        self.current_record = self.get_record_by_row(self.current_row_number)
        self.set_editor_text(self.response_box, updated_record["risposta"])
        self.status_var.set(f"Risposta salvata per la domanda {self.current_row_number}.")

    def save_per_capire_content(self) -> None:
        if self.current_record is None:
            messagebox.showwarning("Nessuna domanda", "Estrai prima una domanda.")
            return

        try:
            updated_record = self.data.save_text_content(
                self.current_row_number,
                "per_capire",
                self.get_editor_text(self.per_capire_box),
            )
        except ValueError as exc:
            messagebox.showwarning("Salvataggio non riuscito", str(exc))
            return

        self.current_record = self.get_record_by_row(self.current_row_number)
        self.set_editor_text(self.per_capire_box, updated_record["per_capire"])
        self.status_var.set(f"Per capire salvato per la domanda {self.current_row_number}.")


def main() -> None:
    if not EXCEL_PATH.exists():
        messagebox.showerror("File mancante", f"Non trovo il file Excel:\n{EXCEL_PATH}")
        return

    try:
        records, dataframe = load_records(EXCEL_PATH)
    except PermissionError as exc:  # pragma: no cover - GUI error handling
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror(
            "File Excel bloccato",
            (
                f"Non riesco ad aprire il file Excel:\n{EXCEL_PATH}\n\n"
                "Chiudi Domande.xlsx se e aperto in Excel o in anteprima, poi riprova."
            ),
        )
        root.destroy()
        return
    except Exception as exc:  # pragma: no cover - GUI error handling
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror("Errore di caricamento", f"Impossibile leggere il file Excel.\n\n{exc}")
        root.destroy()
        return

    globals()["df"] = dataframe

    try:
        root = tk.Tk()
        app = RuotaDellaFortunaGUI(root, records)
    except Exception as exc:  # pragma: no cover - GUI error handling
        fallback_root = tk.Tk()
        fallback_root.withdraw()
        messagebox.showerror("Errore GUI", str(exc))
        fallback_root.destroy()
        return

    app.row_entry.focus_set()
    root.mainloop()


if __name__ == "__main__":
    main()
