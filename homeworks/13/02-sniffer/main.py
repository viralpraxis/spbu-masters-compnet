import threading
import random
import time
import sys
from functools import partial

from core import SnifferEngine
from presenter import Presenter

from kivy.metrics import dp
from kivy.uix.gridlayout import GridLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivymd.app import MDApp
from kivy.uix.label import Label
from kivymd.uix.label.label import MDLabel
from kivymd.uix.datatables import MDDataTable
from kivy.clock import Clock
from kivy.uix.checkbox import CheckBox


class Sniffer(MDApp):
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Orange"

        self.button = Button(text="Start", size_hint_y=None, pos_hint={"bottom": 0})
        self.button.bind(texture_size=self.button.setter("size"))

        self.info_label = MDLabel(text="", padding = (100, 100))

        self.cb_all_label = Label(text="Весь трафик", size_hint=(None,None))
        self.cb_all = CheckBox(group = 'mode', size_hint_x = .02, size_hint_y = .02, active = True)
        self.cb_input_label = Label(text="Входной", size_hint=(None,None))
        self.cb_input = CheckBox(group = 'mode', size_hint_x = .02, size_hint_y = .02)
        self.cb_output_label = Label(text="Выходной", size_hint=(None,None))
        self.cb_output = CheckBox(group = 'mode', size_hint_x = .02, size_hint_y = .02)

        self.cb_mapping = dict()
        self.cb_mapping[self.cb_all] = "all"
        self.cb_mapping[self.cb_input] = "input"
        self.cb_mapping[self.cb_output] = "output"

        self.data_tables = None
        self.row_data=[]
        self.frames_data = dict()

        self.control_layout = BoxLayout(orientation="vertical")
        self.input_layout = BoxLayout(orientation="vertical")
        self.output_layout = BoxLayout(orientation="vertical")

        self.input_layout_label = Label(text="(none)")
        self.output_layout_label = Label(text="(none)")

        self.current_layout = self.data_tables

        self.layout = GridLayout(cols=2)
        self.set_table(self.row_data)
        self.layout.add_widget(self.control_layout)
        self.layout.add_widget(self.data_tables)

        self.sniffer = SnifferEngine()
        self.presenter = Presenter()

        self.src_port_stats = dict()
        self.dest_port_stats = dict()

        return self.layout

    def set_table(self, data):
        self.data_tables = MDDataTable(
            use_pagination=True,
            size_hint=(0.9, 0.6),
            column_data=[
                ("Index", dp(30)),
                ("Timestamp (s)", dp(30)),
                ("From", dp(50)),
                ("To", dp(50))
            ],
            row_data = data
        )

        self.data_tables.bind(on_row_press=self._print_proto_info)
        self.current_layout = self.data_tables

        self.cb_all.bind(active=self._on_checkbox_active)
        self.cb_input.bind(active=self._on_checkbox_active)
        self.cb_output.bind(active=self._on_checkbox_active)

        self.input_layout.add_widget(self.input_layout_label)
        self.output_layout.add_widget(self.output_layout_label)

        self.control_layout.add_widget(self.cb_all_label)
        self.control_layout.add_widget(self.cb_all)
        self.control_layout.add_widget(self.cb_input_label)
        self.control_layout.add_widget(self.cb_input)
        self.control_layout.add_widget(self.cb_output_label)
        self.control_layout.add_widget(self.cb_output)

        self.control_layout.add_widget(self.info_label)
        self.control_layout.add_widget(self.button)

    def on_start(self):
        self.button.bind(on_press=lambda x: self.start_sniffer())

    def start_sniffer(self):
      thread = threading.Thread(target=self._start_sniffer, args=())
      thread.start()

    def _start_sniffer(self):
      time_start = time.time()
      index = 0
      try:
          for frame in self.sniffer.listen(None):
              if random.randrange(0, 200) != 0:
                continue
              index += 1
              ip_src, ip_dest, port_src, port_dest, len, result = self.presenter.present(frame)

              if ip_src is None:
                ip_src = "--"
              if ip_dest is None:
                ip_dest = "--"

              if result:
                new_row_data = [
                  str(index),
                  str(round(time.time() - time_start, 4)),
                  ip_src,
                  ip_dest,
                ]
                Clock.schedule_once(partial(self._add_row, new_row_data, port_src, port_dest, len, result), 1)
      except KeyboardInterrupt:
          sys.exit(0)

    def _add_row(self, row, port_src, port_dest, len, result, *kwargs):
      self.frames_data[str(row[0])] = result
      self.data_tables.row_data.append(row)

      if not port_src in self.src_port_stats:
        self.src_port_stats[port_src] = 0
      self.src_port_stats[port_src] += len

      if not port_dest in self.dest_port_stats:
        self.dest_port_stats[port_dest] = 0
      self.dest_port_stats[port_dest] += len

      self.input_layout_label.text = self._stringify_dict(self.src_port_stats)
      self.output_layout_label.text = self._stringify_dict(self.dest_port_stats)

    def _print_proto_info(self, table, row):
      try:
        ind = table.row_data[row.index][0]
        self.info_label.text = str(self.frames_data[ind])
      except IndexError as e:
        print(e)

    def _on_checkbox_active(self, checkbox, value):
      if value:
        label = self.cb_mapping[checkbox]

        if self.current_layout is None:
          return

        if label == "input":
          self.layout.remove_widget(self.current_layout)
          self.layout.add_widget(self.input_layout)
          self.current_layout = self.input_layout
        elif label == "output":
          self.layout.remove_widget(self.current_layout)
          self.layout.add_widget(self.output_layout)
          self.current_layout = self.output_layout
        else:
          self.layout.remove_widget(self.current_layout)
          self.layout.add_widget(self.data_tables)
          self.current_layout = self.data_tables

    def _stringify_dict(self, d) -> str:
      result = ""

      for k, v in d.items():
        result += f"{k}: {v}\n"

      return result

sniffer = Sniffer()
sniffer.run()
