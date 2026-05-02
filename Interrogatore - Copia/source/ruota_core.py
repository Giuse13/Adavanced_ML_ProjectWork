from __future__ import annotations

import math
import random
from bisect import bisect_left, bisect_right
from pathlib import Path
from tempfile import NamedTemporaryFile
from xml.etree import ElementTree as ET
from zipfile import ZipFile

try:
    import pandas as pd
except ImportError:  # pragma: no cover - fallback if pandas is unavailable
    pd = None


BASE_DIR = Path(__file__).resolve().parent.parent
EXCEL_PATH = BASE_DIR / "Domande.xlsx"
XML_NS = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
SHEET_ENTRY = "xl/worksheets/sheet1.xml"
SOURCE_ROW_KEY = "__sheet_row__"
PREPARATION_MIN = 1
PREPARATION_MAX = 5


def normalize_column_name(value: str) -> str:
    return " ".join(str(value).strip().lower().split())


def is_empty(value) -> bool:
    if value is None:
        return True
    if isinstance(value, float) and math.isnan(value):
        return True
    return str(value).strip() == ""


def format_value(value) -> str:
    if is_empty(value):
        return ""
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value).strip()


def iter_record_values(record: dict):
    for key, value in record.items():
        if str(key).startswith("__"):
            continue
        yield value


def record_has_content(record: dict) -> bool:
    return any(not is_empty(value) for value in iter_record_values(record))


def get_excel_column_letters(cell_ref: str) -> str:
    return "".join(char for char in cell_ref if char.isalpha())


def excel_col_to_index(cell_ref: str) -> int:
    letters = get_excel_column_letters(cell_ref)
    index = 0
    for char in letters:
        index = (index * 26) + (ord(char.upper()) - ord("A") + 1)
    return index


def load_shared_strings(zip_file: ZipFile) -> list[str]:
    try:
        entry = zip_file.open("xl/sharedStrings.xml")
    except KeyError:
        return []

    root = ET.parse(entry).getroot()
    shared_strings = []
    for item in root.findall("main:si", XML_NS):
        text = "".join(node.text or "" for node in item.iterfind(".//main:t", XML_NS))
        shared_strings.append(text)
    return shared_strings


def read_cell_value(cell, shared_strings: list[str]) -> str:
    value_node = cell.find("main:v", XML_NS)
    inline_node = cell.find("main:is/main:t", XML_NS)

    if inline_node is not None:
        return inline_node.text or ""

    if value_node is None or value_node.text is None:
        return ""

    if cell.attrib.get("t") == "s":
        return shared_strings[int(value_node.text)]

    return value_node.text


def read_xlsx_without_pandas(path: Path) -> list[dict]:
    with ZipFile(path) as zip_file:
        shared_strings = load_shared_strings(zip_file)
        sheet_root = ET.parse(zip_file.open(SHEET_ENTRY)).getroot()

    rows = []
    for row in sheet_root.findall("main:sheetData/main:row", XML_NS):
        row_values = {}
        for cell in row.findall("main:c", XML_NS):
            cell_ref = cell.attrib.get("r", "")
            column_letters = get_excel_column_letters(cell_ref)
            row_values[column_letters] = read_cell_value(cell, shared_strings)
        row_number = int(row.attrib.get("r", len(rows) + 1))
        rows.append((row_number, row_values))

    if not rows:
        return []

    _header_sheet_row, header_row = rows[0]
    header_cells = sorted(header_row, key=excel_col_to_index)
    headers = [header_row[cell] for cell in header_cells]
    records = []

    for sheet_row_number, raw_row in rows[1:]:
        record = {SOURCE_ROW_KEY: sheet_row_number}
        for cell_ref, header in zip(header_cells, headers):
            record[header] = raw_row.get(cell_ref, "")
        records.append(record)

    return records


def load_records(path: Path) -> tuple[list[dict], object]:
    if pd is not None:
        dataframe = pd.read_excel(path)
        records = []
        for index, record in enumerate(dataframe.to_dict(orient="records"), start=2):
            item = dict(record)
            item[SOURCE_ROW_KEY] = index
            records.append(item)

        kept_indices = [index for index, record in enumerate(records) if record_has_content(record)]
        filtered_records = [records[index] for index in kept_indices]
        filtered_dataframe = dataframe.iloc[kept_indices].reset_index(drop=True)
        return filtered_records, filtered_dataframe

    records = read_xlsx_without_pandas(path)
    filtered_records = [record for record in records if record_has_content(record)]
    return filtered_records, filtered_records


def find_column(columns: list[str], *candidates: str) -> str | None:
    normalized_map = {normalize_column_name(column): column for column in columns}
    for candidate in candidates:
        found = normalized_map.get(normalize_column_name(candidate))
        if found:
            return found
    return None


def parse_preparation_level(value) -> int | None:
    if is_empty(value):
        return None

    if isinstance(value, int):
        level = value
    elif isinstance(value, float):
        if value.is_integer():
            level = int(value)
        else:
            raise ValueError("Il livello di preparazione deve essere un intero tra 1 e 5.")
    else:
        text = str(value).strip().replace(",", ".")
        try:
            numeric = float(text)
        except ValueError as exc:
            raise ValueError("Il livello di preparazione deve essere un intero tra 1 e 5.") from exc
        if not numeric.is_integer():
            raise ValueError("Il livello di preparazione deve essere un intero tra 1 e 5.")
        level = int(numeric)

    if level < PREPARATION_MIN or level > PREPARATION_MAX:
        raise ValueError("Il livello di preparazione deve essere compreso tra 1 e 5.")

    return level


def matches_preparation_filter(level: int | None, selected_levels: set[int] | None) -> bool:
    if not selected_levels:
        return True
    if level is None:
        return False
    return level in selected_levels


def find_sheet_column_letter(sheet_root, header_name: str, shared_strings: list[str]) -> str:
    header_row = sheet_root.find("main:sheetData/main:row", XML_NS)
    if header_row is None:
        raise ValueError("Il foglio Excel non contiene una riga intestazione.")

    normalized_target = normalize_column_name(header_name)
    for cell in header_row.findall("main:c", XML_NS):
        if normalize_column_name(read_cell_value(cell, shared_strings)) == normalized_target:
            return get_excel_column_letters(cell.attrib.get("r", ""))

    raise ValueError(f"Colonna non trovata nel file Excel: {header_name}")


def upsert_numeric_cell(row_node, cell_ref: str, numeric_value: int) -> None:
    cell_node = None
    for candidate in row_node.findall("main:c", XML_NS):
        if candidate.attrib.get("r") == cell_ref:
            cell_node = candidate
            break

    if cell_node is None:
        cell_node = ET.Element(f"{{{MAIN_NS}}}c", {"r": cell_ref})
        row_node.append(cell_node)

    cell_node.attrib.pop("t", None)
    for child in list(cell_node):
        cell_node.remove(child)

    value_node = ET.SubElement(cell_node, f"{{{MAIN_NS}}}v")
    value_node.text = str(numeric_value)


def upsert_text_cell(row_node, cell_ref: str, text_value: str) -> None:
    cell_node = None
    for candidate in row_node.findall("main:c", XML_NS):
        if candidate.attrib.get("r") == cell_ref:
            cell_node = candidate
            break

    if cell_node is None:
        cell_node = ET.Element(f"{{{MAIN_NS}}}c", {"r": cell_ref})
        row_node.append(cell_node)

    cell_node.attrib["t"] = "inlineStr"
    for child in list(cell_node):
        cell_node.remove(child)

    inline_node = ET.SubElement(cell_node, f"{{{MAIN_NS}}}is")
    text_node = ET.SubElement(inline_node, f"{{{MAIN_NS}}}t")
    text_node.text = text_value
    if text_value.strip() != text_value:
        text_node.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")


def save_cell_to_xlsx(path: Path, sheet_row_number: int, header_name: str, value, *, is_text: bool) -> None:
    with ZipFile(path, "r") as source_zip:
        shared_strings = load_shared_strings(source_zip)
        sheet_root = ET.fromstring(source_zip.read(SHEET_ENTRY))
        target_column = find_sheet_column_letter(sheet_root, header_name, shared_strings)
        target_ref = f"{target_column}{sheet_row_number}"
        row_node = None

        for candidate in sheet_root.findall("main:sheetData/main:row", XML_NS):
            if int(candidate.attrib.get("r", "0")) == sheet_row_number:
                row_node = candidate
                break

        if row_node is None:
            raise ValueError(f"Non trovo la riga Excel reale {sheet_row_number}.")

        if is_text:
            upsert_text_cell(row_node, target_ref, str(value))
        else:
            upsert_numeric_cell(row_node, target_ref, int(value))
        updated_sheet_xml = ET.tostring(sheet_root, encoding="utf-8", xml_declaration=True)

        with NamedTemporaryFile(delete=False, suffix=path.suffix, dir=path.parent) as temp_file:
            temp_path = Path(temp_file.name)

        with ZipFile(temp_path, "w") as target_zip:
            for info in source_zip.infolist():
                if info.filename == SHEET_ENTRY:
                    target_zip.writestr(info, updated_sheet_xml)
                else:
                    target_zip.writestr(info, source_zip.read(info.filename))

    temp_path.replace(path)


def save_numeric_cell_to_xlsx(path: Path, sheet_row_number: int, header_name: str, numeric_value: int) -> None:
    save_cell_to_xlsx(path, sheet_row_number, header_name, numeric_value, is_text=False)


def save_text_cell_to_xlsx(path: Path, sheet_row_number: int, header_name: str, text_value: str) -> None:
    save_cell_to_xlsx(path, sheet_row_number, header_name, text_value, is_text=True)


class RuotaData:
    def __init__(self, records: list[dict], excel_path: Path = EXCEL_PATH):
        if not records:
            raise ValueError("Il file Excel non contiene righe dati.")

        self.records = records
        self.excel_path = excel_path
        self.columns = [column for column in self.records[0].keys() if not str(column).startswith("__")]
        self.slide_col = find_column(self.columns, "Slide")
        self.argomento_col = find_column(self.columns, "Argomento")
        self.domanda_col = find_column(self.columns, "Domanda")
        self.risposta_col = find_column(self.columns, "Risposta")
        self.per_capire_col = find_column(self.columns, "Per capire", "Per_capire")
        self.preparation_col = find_column(
            self.columns,
            "Liv. Preparazione",
            "Liv Preparazione",
            "Liv_preparazione",
            "LivPreparazione",
        )

        missing = [
            name
            for name, column in (
                ("Slide", self.slide_col),
                ("Argomento", self.argomento_col),
                ("Domanda", self.domanda_col),
                ("Risposta", self.risposta_col),
                ("Per capire", self.per_capire_col),
                ("Liv. Preparazione", self.preparation_col),
            )
            if column is None
        ]
        if missing:
            raise ValueError(f"Colonne mancanti nel file Excel: {', '.join(missing)}")

        self.question_row_indices = [
            index + 1
            for index, record in enumerate(self.records)
            if not is_empty(record.get(self.domanda_col, ""))
        ]
        if not self.question_row_indices:
            raise ValueError("Non ci sono domande disponibili nel file Excel.")

    @property
    def total_rows(self) -> int:
        return len(self.records)

    def get_record_by_row(self, row_number: int) -> dict:
        if row_number < 1 or row_number > len(self.records):
            raise IndexError
        return self.records[row_number - 1]

    def get_preparation_level(self, record: dict) -> int | None:
        return parse_preparation_level(record.get(self.preparation_col, ""))

    def describe_filter(self, preparation_filter) -> str:
        selected_levels = self.parse_preparation_filter(preparation_filter)
        if not selected_levels:
            return "senza filtro"
        ordered_levels = ", ".join(str(level) for level in sorted(selected_levels))
        return f"con Liv. Preparazione in [{ordered_levels}]"

    def serialize_record(self, row_number: int) -> dict:
        record = self.get_record_by_row(row_number)
        per_capire = format_value(record.get(self.per_capire_col, ""))
        return {
            "row_number": row_number,
            "slide": format_value(record.get(self.slide_col, "")) or "-",
            "argomento": format_value(record.get(self.argomento_col, "")) or "-",
            "domanda": format_value(record.get(self.domanda_col, "")) or "-",
            "risposta": format_value(record.get(self.risposta_col, "")),
            "per_capire": per_capire,
            "has_per_capire": bool(per_capire),
            "preparation_level": self.get_preparation_level(record),
        }

    def parse_requested_row(self, raw_value: str) -> int:
        clean_value = raw_value.strip()
        if not clean_value.isdigit():
            raise ValueError("Inserisci un numero intero.")

        row_number = int(clean_value)
        self.get_record_by_row(row_number)
        return row_number

    def parse_preparation_filter(self, value) -> set[int] | None:
        if value in (None, "", "all"):
            return None

        if isinstance(value, int):
            raw_levels = [value]
        elif isinstance(value, (list, tuple, set)):
            raw_levels = list(value)
        else:
            text = str(value).strip()
            if not text:
                return None
            raw_levels = [chunk.strip() for chunk in text.split(",") if chunk.strip()]

        selected_levels: set[int] = set()
        for item in raw_levels:
            text = str(item).strip()
            if not text.isdigit():
                raise ValueError("Il filtro di preparazione non e valido.")
            level = int(text)
            if level < PREPARATION_MIN or level > PREPARATION_MAX:
                raise ValueError("Il filtro di preparazione non e valido.")
            selected_levels.add(level)

        return selected_levels or None

    def get_filtered_row_numbers(self, preparation_filter) -> list[int]:
        selected_levels = self.parse_preparation_filter(preparation_filter)
        eligible_rows = [
            row_number
            for row_number in self.question_row_indices
            if matches_preparation_filter(
                self.get_preparation_level(self.get_record_by_row(row_number)),
                selected_levels,
            )
        ]

        if not eligible_rows:
            if not selected_levels:
                raise ValueError("Non ci sono domande disponibili.")
            ordered_levels = ", ".join(str(level) for level in sorted(selected_levels))
            raise ValueError(f"Non ci sono domande con Liv. Preparazione in [{ordered_levels}].")

        return eligible_rows

    def ensure_row_matches_filter(self, row_number: int, preparation_filter) -> None:
        selected_levels = self.parse_preparation_filter(preparation_filter)
        if row_number not in self.get_filtered_row_numbers(preparation_filter):
            ordered_levels = ", ".join(str(level) for level in sorted(selected_levels or []))
            raise ValueError(
                f"La domanda {row_number} non rientra nel filtro attivo (Liv. Preparazione in [{ordered_levels}])."
            )

    def get_navigation_base_row(
        self,
        raw_value: str,
        current_row_number: int | None,
        preparation_filter=None,
    ) -> int:
        eligible_rows = self.get_filtered_row_numbers(preparation_filter)
        if current_row_number is not None and current_row_number in eligible_rows:
            return current_row_number

        clean_value = raw_value.strip()
        if clean_value.isdigit():
            return int(clean_value)

        return eligible_rows[0]

    def go_previous_row(
        self,
        raw_value: str,
        current_row_number: int | None,
        preparation_filter=None,
    ) -> tuple[int, dict, str]:
        eligible_rows = self.get_filtered_row_numbers(preparation_filter)
        base_row = self.get_navigation_base_row(raw_value, current_row_number, preparation_filter)
        target_index = bisect_left(eligible_rows, base_row) - 1

        if target_index < 0:
            target_row = eligible_rows[0]
            return (
                target_row,
                self.serialize_record(target_row),
                f"Sei gia alla prima domanda disponibile {self.describe_filter(preparation_filter)}: {target_row}.",
            )

        target_row = eligible_rows[target_index]
        return (
            target_row,
            self.serialize_record(target_row),
            f"Domanda precedente caricata {self.describe_filter(preparation_filter)}: {target_row}.",
        )

    def go_next_row(
        self,
        raw_value: str,
        current_row_number: int | None,
        preparation_filter=None,
    ) -> tuple[int, dict, str]:
        eligible_rows = self.get_filtered_row_numbers(preparation_filter)
        base_row = self.get_navigation_base_row(raw_value, current_row_number, preparation_filter)

        if base_row in eligible_rows:
            target_index = bisect_right(eligible_rows, base_row)
        else:
            target_index = bisect_left(eligible_rows, base_row)

        if target_index >= len(eligible_rows):
            target_row = eligible_rows[-1]
            return (
                target_row,
                self.serialize_record(target_row),
                f"Sei gia all'ultima domanda disponibile {self.describe_filter(preparation_filter)}: {target_row}.",
            )

        target_row = eligible_rows[target_index]
        return (
            target_row,
            self.serialize_record(target_row),
            f"Domanda successiva caricata {self.describe_filter(preparation_filter)}: {target_row}.",
        )

    def extract_row(
        self,
        raw_value: str,
        shuffle_active: bool,
        preparation_filter=None,
    ) -> tuple[int, dict, str]:
        selected_levels = self.parse_preparation_filter(preparation_filter)
        eligible_rows = self.get_filtered_row_numbers(preparation_filter)
        requested_row_number: int | None = None
        clean_value = raw_value.strip()

        if not shuffle_active:
            requested_row_number = self.parse_requested_row(clean_value)
            self.ensure_row_matches_filter(requested_row_number, preparation_filter)
        elif clean_value.isdigit():
            candidate_row_number = int(clean_value)
            if 1 <= candidate_row_number <= len(self.records):
                requested_row_number = candidate_row_number

        actual_row_number = requested_row_number or eligible_rows[0]
        if shuffle_active:
            actual_row_number = random.choice(eligible_rows)

        if selected_levels:
            ordered_levels = ", ".join(str(level) for level in sorted(selected_levels))
            filter_suffix = f" nel filtro Liv. Preparazione in [{ordered_levels}]"
        else:
            filter_suffix = ""
        if shuffle_active and requested_row_number is not None:
            status_message = (
                f"Shuffle attivo{filter_suffix}: richiesta domanda {requested_row_number}, "
                f"estratta casualmente domanda {actual_row_number}."
            )
        elif shuffle_active:
            status_message = f"Shuffle attivo{filter_suffix}: estratta casualmente domanda {actual_row_number}."
        else:
            status_message = f"Domanda {actual_row_number} caricata correttamente{filter_suffix}."

        return actual_row_number, self.serialize_record(actual_row_number), status_message

    def save_preparation_level(self, row_number: int, level) -> dict:
        record = self.get_record_by_row(row_number)
        parsed_level = parse_preparation_level(level)
        if parsed_level is None:
            raise ValueError("Il livello di preparazione deve essere compreso tra 1 e 5.")

        sheet_row_number = record.get(SOURCE_ROW_KEY)
        if sheet_row_number is None:
            raise ValueError("Non trovo la riga originale del foglio Excel per questa domanda.")

        save_numeric_cell_to_xlsx(
            self.excel_path,
            int(sheet_row_number),
            self.preparation_col,
            parsed_level,
        )
        record[self.preparation_col] = parsed_level
        return self.serialize_record(row_number)

    def save_text_content(self, row_number: int, field: str, text_value: str) -> dict:
        record = self.get_record_by_row(row_number)
        sheet_row_number = record.get(SOURCE_ROW_KEY)
        if sheet_row_number is None:
            raise ValueError("Non trovo la riga originale del foglio Excel per questa domanda.")

        field_map = {
            "risposta": self.risposta_col,
            "per_capire": self.per_capire_col,
        }
        target_column = field_map.get(field)
        if target_column is None:
            raise ValueError("Campo testuale non valido.")

        normalized_text = str(text_value).replace("\r\n", "\n")
        save_text_cell_to_xlsx(
            self.excel_path,
            int(sheet_row_number),
            target_column,
            normalized_text,
        )
        record[target_column] = normalized_text
        return self.serialize_record(row_number)
