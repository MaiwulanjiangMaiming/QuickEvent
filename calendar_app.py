import sys
import os
import PyQt6

# Fix for "Could not find the Qt platform plugin 'cocoa'" error
# 1. Clear any existing QT_PLUGIN_PATH that might conflict
if 'QT_PLUGIN_PATH' in os.environ:
    del os.environ['QT_PLUGIN_PATH']

# 2. Explicitly set the plugin path based on the installed PyQt6 location
dirname = os.path.dirname(PyQt6.__file__)
plugin_path = os.path.join(dirname, 'Qt6', 'plugins')
os.environ['QT_PLUGIN_PATH'] = plugin_path

from datetime import datetime, timedelta
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                            QHBoxLayout, QLabel, QLineEdit, QPushButton, 
                            QComboBox, QDateTimeEdit, QSpinBox, QDoubleSpinBox,
                            QTableWidget, QTableWidgetItem, 
                            QHeaderView, QFileDialog, QMessageBox, QGroupBox,
                            QFormLayout)
from PyQt6.QtCore import Qt, QDateTime
from ics import Calendar, Event, DisplayAlarm

from ics.grammar.parse import ContentLine

# ... Logic ...

class TaskManager:
    def __init__(self):
        self.tasks = []

    def add_task(self, task_data):
        self.tasks.append(task_data)

    def generate_ics(self, file_path):
        calendar = Calendar()
        for task in self.tasks:
            try:
                events = self.create_events(task)
                for e in events:
                    calendar.events.add(e)
            except Exception as e:
                print(f"Error creating event for task {task.get('title')}: {e}")
                continue
        
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(str(calendar))

    def create_events(self, task):
        start_dt = task["start_time"] # datetime object
        duration_td = timedelta(hours=task["duration_hours"])
        events = []

        for day_offset in range(task["multi_days"]):
            e = Event()
            e.name = task["title"]
            e.begin = start_dt + timedelta(days=day_offset)
            e.duration = duration_td
            e.categories = {task["category"]} if task["category"] else set()
            e.description = f"Priority: {task['priority']}"

            if task["repeat"] and task["repeat"] != "NONE":
                rule = f"FREQ={task['repeat']};INTERVAL={task['interval']}"
                if task["by_day"]:
                    rule += f";BYDAY={task['by_day']}"
                e.extra.append(ContentLine(name="RRULE", value=rule))

            if task["remind_before"] > 0:
                e.alarms.append(DisplayAlarm(trigger=timedelta(minutes=-task["remind_before"])))

            events.append(e)
        return events

# --- Styles ---

KALI_DARK_STYLE = """
QMainWindow {
    background-color: #0d1117;
    color: #00ff00;
}
QWidget {
    background-color: #0d1117;
    color: #e6edf3;
    font-family: "Menlo", "Consolas", "Courier New", monospace;
    font-size: 13px;
}
QGroupBox {
    border: 1px solid #30363d;
    border-radius: 5px;
    margin-top: 10px;
    color: #00ffff;
    font-weight: bold;
    padding-top: 15px;
}
QGroupBox::title {
    subcontrol-origin: margin;
    subcontrol-position: top left;
    padding: 0 5px;
}
QLabel {
    color: #00ffff;
    font-weight: bold;
}
QLineEdit, QSpinBox, QDoubleSpinBox, QDateTimeEdit, QComboBox {
    background-color: #161b22;
    border: 1px solid #30363d;
    border-radius: 4px;
    color: #e6edf3;
    padding: 5px;
    min-height: 20px;
}
QLineEdit:focus, QSpinBox:focus, QComboBox:focus, QDoubleSpinBox:focus {
    border: 1px solid #00ff00;
}
/* Restore standard arrow look but colored for theme */
QSpinBox::up-button, QDoubleSpinBox::up-button {
    subcontrol-origin: border;
    subcontrol-position: top right;
    width: 16px;
    border-left: 1px solid #30363d;
    border-bottom: 1px solid #30363d;
    background: #161b22;
}
QSpinBox::down-button, QDoubleSpinBox::down-button {
    subcontrol-origin: border;
    subcontrol-position: bottom right;
    width: 16px;
    border-left: 1px solid #30363d;
    border-top: none;
    background: #161b22;
}
QSpinBox::up-button:hover, QDoubleSpinBox::up-button:hover, 
QSpinBox::down-button:hover, QDoubleSpinBox::down-button:hover {
    background-color: #21262d;
}
QSpinBox::up-arrow, QDoubleSpinBox::up-arrow {
    width: 8px;
    height: 8px;
    image: none;
    border-left: 4px solid none;
    border-right: 4px solid none;
    border-bottom: 4px solid #00ff00; /* Bright Green Arrow */
}
QSpinBox::down-arrow, QDoubleSpinBox::down-arrow {
    width: 8px;
    height: 8px;
    image: none;
    border-left: 4px solid none;
    border-right: 4px solid none;
    border-top: 4px solid #00ff00; /* Bright Green Arrow */
}

QPushButton {
    background-color: #238636;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    font-weight: bold;
}
QPushButton:hover {
    background-color: #2ea043;
}
QPushButton#DayButton {
    background-color: #21262d;
    color: #8b949e;
    border: 1px solid #30363d;
    padding: 5px;
    min-width: 30px;
}
QPushButton#DayButton:checked {
    background-color: #238636;
    color: white;
    border: 1px solid #238636;
}
QTableWidget {
    background-color: #161b22;
    border: 1px solid #30363d;
    gridline-color: #30363d;
    color: #e6edf3;
    selection-background-color: #1f6feb;
}
QHeaderView::section {
    background-color: #21262d;
    color: #e6edf3;
    padding: 6px;
    border: 1px solid #30363d;
    font-weight: bold;
}
QScrollBar:vertical {
    border: none;
    background: #0d1117;
    width: 12px;
    margin: 0px;
}
QScrollBar::handle:vertical {
    background: #30363d;
    min-height: 20px;
    border-radius: 6px;
}
"""

LIGHT_STYLE = """
QMainWindow {
    background-color: #ffffff;
    color: #000000;
}
QWidget {
    background-color: #ffffff;
    color: #24292f;
    /* Use SAME font as Dark Mode for consistency */
    font-family: "Menlo", "Consolas", "Courier New", monospace;
    font-size: 13px;
}
QGroupBox {
    border: 1px solid #d0d7de;
    border-radius: 6px;
    margin-top: 10px;
    color: #0969da;
    font-weight: bold;
    padding-top: 15px;
}
QGroupBox::title {
    subcontrol-origin: margin;
    subcontrol-position: top left;
    padding: 0 5px;
}
QLabel {
    color: #24292f;
    font-weight: 600;
}
QLineEdit, QSpinBox, QDoubleSpinBox, QDateTimeEdit, QComboBox {
    background-color: #ffffff;
    border: 1px solid #d0d7de;
    border-radius: 6px;
    color: #24292f;
    padding: 6px;
    min-height: 20px;
}
QLineEdit:focus, QSpinBox:focus, QComboBox:focus, QDoubleSpinBox:focus {
    border: 2px solid #0969da;
    outline: none;
}
/* Standard arrow look for Light Mode */
QSpinBox::up-button, QDoubleSpinBox::up-button {
    subcontrol-origin: border;
    subcontrol-position: top right;
    width: 16px;
    border-left: 1px solid #d0d7de;
    border-bottom: 1px solid #d0d7de;
    background: #f6f8fa;
}
QSpinBox::down-button, QDoubleSpinBox::down-button {
    subcontrol-origin: border;
    subcontrol-position: bottom right;
    width: 16px;
    border-left: 1px solid #d0d7de;
    border-top: none;
    background: #f6f8fa;
}
QSpinBox::up-button:hover, QDoubleSpinBox::up-button:hover, 
QSpinBox::down-button:hover, QDoubleSpinBox::down-button:hover {
    background-color: #eaeef2;
}
QSpinBox::up-arrow, QDoubleSpinBox::up-arrow {
    width: 8px;
    height: 8px;
    image: none;
    border-left: 4px solid none;
    border-right: 4px solid none;
    border-bottom: 4px solid #57606a;
}
QSpinBox::down-arrow, QDoubleSpinBox::down-arrow {
    width: 8px;
    height: 8px;
    image: none;
    border-left: 4px solid none;
    border-right: 4px solid none;
    border-top: 4px solid #57606a;
}
QPushButton {
    background-color: #0969da;
    color: white;
    border: 1px solid rgba(27,31,36,0.15);
    padding: 8px 16px;
    border-radius: 6px;
    font-weight: 600;
    box-shadow: 0 1px 0 rgba(27,31,36,0.1);
}
QPushButton:hover {
    background-color: #0a5cc0;
}
QPushButton#DayButton {
    background-color: #f6f8fa;
    color: #24292f;
    border: 1px solid #d0d7de;
    padding: 6px;
    min-width: 30px;
    font-weight: normal;
}
QPushButton#DayButton:checked {
    background-color: #0969da;
    color: white;
    border: 1px solid #0969da;
    font-weight: 600;
}
QTableWidget {
    background-color: #ffffff;
    border: 1px solid #d0d7de;
    gridline-color: #d0d7de;
    color: #24292f;
    selection-background-color: #0969da;
    selection-color: #ffffff;
    alternate-background-color: #f6f8fa;
}
QHeaderView::section {
    background-color: #f6f8fa;
    color: #24292f;
    padding: 8px;
    border: 1px solid #d0d7de;
    font-weight: 600;
}
QScrollBar:vertical {
    border: none;
    background: #f6f8fa;
    width: 12px;
    margin: 0px;
}
QScrollBar::handle:vertical {
    background: #d0d7de;
    min-height: 20px;
    border-radius: 6px;
}
QScrollBar::handle:vertical:hover {
    background: #afb8c1;
}
"""

# --- UI Components ---

class DaySelector(QWidget):
    def __init__(self):
        super().__init__()
        self.days_layout = QHBoxLayout(self)
        self.days_layout.setContentsMargins(0, 0, 0, 0)
        self.days_layout.setSpacing(4)
        
        self.days = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
        self.buttons = {}
        
        for day in self.days:
            btn = QPushButton(day)
            btn.setObjectName("DayButton")
            btn.setCheckable(True)
            btn.setCursor(Qt.CursorShape.PointingHandCursor)
            self.days_layout.addWidget(btn)
            self.buttons[day] = btn

    def get_selected_days(self):
        selected = [day for day, btn in self.buttons.items() if btn.isChecked()]
        return ",".join(selected) if selected else None

    def clear(self):
        for btn in self.buttons.values():
            btn.setChecked(False)

class CalendarApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.task_manager = TaskManager()
        self.is_dark_mode = True
        
        self.setWindowTitle("Calendar Generator")
        self.setGeometry(100, 100, 1100, 750)
        
        # Main Widget
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.main_layout = QHBoxLayout(self.central_widget)
        self.main_layout.setSpacing(20)
        self.main_layout.setContentsMargins(20, 20, 20, 20)

        # Left Panel: Inputs
        self.create_input_panel()
        
        # Right Panel: List & Actions
        self.create_list_panel()
        
        # Apply Initial Theme
        self.apply_theme()

    def create_input_panel(self):
        self.input_group = QGroupBox("Create Task")
        self.input_layout = QFormLayout()
        self.input_layout.setLabelAlignment(Qt.AlignmentFlag.AlignLeft)
        self.input_layout.setFieldGrowthPolicy(QFormLayout.FieldGrowthPolicy.ExpandingFieldsGrow)
        self.input_layout.setContentsMargins(15, 20, 15, 15)
        self.input_layout.setVerticalSpacing(12)
        
        # Title
        self.title_input = QLineEdit()
        self.title_input.setPlaceholderText("Enter task title...")
        self.input_layout.addRow(QLabel("Task Title:"), self.title_input)
        
        # Start Time
        self.start_time_input = QDateTimeEdit(QDateTime.currentDateTime())
        self.start_time_input.setDisplayFormat("yyyy-MM-dd HH:mm")
        self.start_time_input.setCalendarPopup(True)
        self.input_layout.addRow(QLabel("Start Time:"), self.start_time_input)
        
        # Duration
        self.duration_input = QDoubleSpinBox()
        self.duration_input.setRange(0, 100)
        self.duration_input.setValue(1.0)
        self.duration_input.setSingleStep(0.5)
        self.duration_input.setSuffix(" hours")
        self.input_layout.addRow(QLabel("Duration:"), self.duration_input)
        
        # Category
        self.category_input = QLineEdit()
        self.category_input.setPlaceholderText("Work, Personal, etc.")
        self.input_layout.addRow(QLabel("Category:"), self.category_input)
        
        # Priority
        self.priority_input = QComboBox()
        self.priority_input.addItems(["High", "Medium", "Low"])
        self.priority_input.setCurrentText("Medium")
        self.input_layout.addRow(QLabel("Priority:"), self.priority_input)
        
        # Repeat
        self.repeat_input = QComboBox()
        self.repeat_input.addItems(["NONE", "DAILY", "WEEKLY", "MONTHLY"])
        self.repeat_input.currentTextChanged.connect(self.toggle_repeat_options)
        self.input_layout.addRow(QLabel("Repeat:"), self.repeat_input)
        
        # Repeat Options (Hidden by default)
        self.repeat_options_widget = QWidget()
        self.repeat_layout = QVBoxLayout(self.repeat_options_widget)
        self.repeat_layout.setContentsMargins(0, 0, 0, 0)
        self.repeat_layout.setSpacing(10)
        
        self.interval_input = QSpinBox()
        self.interval_input.setRange(1, 365)
        self.interval_input.setPrefix("Every ")
        self.interval_input.setSuffix(" interval(s)")
        
        self.day_selector = DaySelector()
        
        self.repeat_layout.addWidget(self.interval_input)
        self.repeat_layout.addWidget(self.day_selector)
        self.input_layout.addRow(QLabel("Repeat Rules:"), self.repeat_options_widget)
        self.repeat_options_widget.hide()

        # Reminder
        self.remind_input = QSpinBox()
        self.remind_input.setRange(0, 1440)
        self.remind_input.setValue(0)
        self.remind_input.setSuffix(" min before")
        self.input_layout.addRow(QLabel("Reminder:"), self.remind_input)
        
        # Multi-days
        self.multiday_input = QSpinBox()
        self.multiday_input.setRange(1, 365)
        self.multiday_input.setValue(1)
        self.multiday_input.setSuffix(" days")
        self.input_layout.addRow(QLabel("Duration (Days):"), self.multiday_input)

        # Add Button (Spacer to push to bottom if needed, or just add)
        self.add_btn = QPushButton("Add Task")
        self.add_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.add_btn.clicked.connect(self.add_task)
        
        # Container for button to center it or style it separately
        btn_container = QWidget()
        btn_layout = QHBoxLayout(btn_container)
        btn_layout.setContentsMargins(0, 10, 0, 0)
        btn_layout.addWidget(self.add_btn)
        
        self.input_layout.addRow(btn_container)

        self.input_group.setLayout(self.input_layout)
        self.main_layout.addWidget(self.input_group, 1)

    def create_list_panel(self):
        self.list_widget = QWidget()
        self.list_layout = QVBoxLayout(self.list_widget)
        self.list_layout.setContentsMargins(0, 0, 0, 0)
        self.list_layout.setSpacing(10)
        
        # Header with Theme Toggle
        header_layout = QHBoxLayout()
        title_lbl = QLabel("Task List")
        title_lbl.setStyleSheet("font-size: 16px; border: none;")
        
        self.theme_btn = QPushButton("Toggle Theme")
        self.theme_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.theme_btn.clicked.connect(self.toggle_theme)
        # Removed fixed width to allow text to fit
        
        header_layout.addWidget(title_lbl)
        header_layout.addStretch()
        header_layout.addWidget(self.theme_btn)
        self.list_layout.addLayout(header_layout)

        # Table
        self.table = QTableWidget()
        self.table.setColumnCount(6)
        self.table.setHorizontalHeaderLabels(["Title", "Start", "Duration", "Category", "Repeat", "Priority"])
        
        header = self.table.horizontalHeader()
        if header:
            header.setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
            
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.list_layout.addWidget(self.table)
        
        # Export Button
        self.export_btn = QPushButton("Generate ICS Calendar")
        self.export_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.export_btn.clicked.connect(self.export_calendar)
        self.export_btn.setStyleSheet("""
            QPushButton {
                background-color: #005cc5; 
                color: white;
                font-size: 14px; 
                padding: 12px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #004d99;
            }
        """)
        self.list_layout.addWidget(self.export_btn)
        
        self.main_layout.addWidget(self.list_widget, 2)

    def toggle_repeat_options(self, text):
        if text == "NONE":
            self.repeat_options_widget.hide()
        else:
            self.repeat_options_widget.show()
            # Show day selector only for WEEKLY
            if text == "WEEKLY":
                self.day_selector.show()
            else:
                self.day_selector.hide()

    def add_task(self):
        title = self.title_input.text().strip()
        if not title:
            QMessageBox.warning(self, "Input Error", "Task title is required!")
            return
            
        by_day = None
        if self.repeat_input.currentText() == "WEEKLY":
            by_day = self.day_selector.get_selected_days()

        task = {
            "title": title,
            "start_time": self.start_time_input.dateTime().toPyDateTime(),
            "duration_hours": float(self.duration_input.value()),
            "category": self.category_input.text().strip(),
            "priority": self.priority_input.currentText(),
            "repeat": self.repeat_input.currentText(),
            "interval": self.interval_input.value(),
            "by_day": by_day,
            "remind_before": self.remind_input.value(),
            "multi_days": self.multiday_input.value()
        }
        
        self.task_manager.add_task(task)
        self.update_table()
        self.clear_inputs()

    def update_table(self):
        self.table.setRowCount(len(self.task_manager.tasks))
        for i, task in enumerate(self.task_manager.tasks):
            self.table.setItem(i, 0, QTableWidgetItem(task["title"]))
            self.table.setItem(i, 1, QTableWidgetItem(task["start_time"].strftime("%Y-%m-%d %H:%M")))
            self.table.setItem(i, 2, QTableWidgetItem(str(task["duration_hours"])))
            self.table.setItem(i, 3, QTableWidgetItem(task["category"]))
            self.table.setItem(i, 4, QTableWidgetItem(task["repeat"]))
            self.table.setItem(i, 5, QTableWidgetItem(task["priority"]))

    def clear_inputs(self):
        self.title_input.clear()
        self.category_input.clear()
        self.day_selector.clear()
        self.title_input.setFocus()

    def export_calendar(self):
        if not self.task_manager.tasks:
            QMessageBox.warning(self, "No Tasks", "Please add tasks before generating calendar.")
            return

        # Let user choose folder
        folder_path = QFileDialog.getExistingDirectory(self, "Select Directory to Save ICS")
        if folder_path:
            file_name = f"tasks_calendar_{datetime.now().strftime('%Y%m%d_%H%M%S')}.ics"
            full_path = os.path.join(folder_path, file_name)
            
            try:
                self.task_manager.generate_ics(full_path)
                QMessageBox.information(self, "Success", f"Calendar generated successfully at:\n{full_path}")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to save file:\n{str(e)}")

    def toggle_theme(self):
        self.is_dark_mode = not self.is_dark_mode
        self.apply_theme()

    def apply_theme(self):
        if self.is_dark_mode:
            self.setStyleSheet(KALI_DARK_STYLE)
        else:
            self.setStyleSheet(LIGHT_STYLE)

def main():
    app = QApplication(sys.argv)
    window = CalendarApp()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
