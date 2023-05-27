import sys
from functools import partial

from engine import Engine
from self_resolver import SelfResolver

from kivy.metrics import dp
from kivy.uix.gridlayout import GridLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.progressbar import ProgressBar
from kivy.uix.button import Button
from kivymd.app import MDApp
from kivymd.uix.datatables import MDDataTable
from kivy.uix.textinput import TextInput
from kivy.clock import Clock

import threading

class NMap(MDApp):
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Orange"

        self.button = Button(text="Start", size_hint_y=None, pos_hint={"bottom": 0})
        self.button.bind(texture_size=self.button.setter("size"))

        self.textinput_netmask = TextInput(text="Netmask", multiline=False)
        self.pb = None

        self.data_tables = None
        self.row_data=[]

        self.control_layout = BoxLayout(orientation="vertical")

        self.layout = GridLayout(cols=2)
        self.set_table(self.row_data)
        self.layout.add_widget(self.data_tables)
        self.layout.add_widget(self.control_layout)

        return self.layout

    def set_table(self, data):
        self.data_tables = MDDataTable(
            size_hint=(0.9, 0.6),
            column_data=[
                ("IP address", dp(30)),
                ("MAC address", dp(50)),
                ("Hostname", dp(50))
            ],
            row_data = data
        )

        self.control_layout.add_widget(self.button)
        self.control_layout.add_widget(self.textinput_netmask)

    def on_start(self):
        self.button.bind(on_press=lambda x: self.addrow())

    def addrow(self):
        current_netmask = self.textinput_netmask.text
        engine = Engine(current_netmask)
        if self.pb is None:
          self.pb = ProgressBar(max=engine.total)
          self.control_layout.add_widget(self.pb)
        else:
          self.pb.value = 0

        self.data_tables.row_data = []

        self_resolver = SelfResolver(current_netmask)
        resolved = self_resolver.resolve()
        self.data_tables.row_data.append(resolved)

        Clock.schedule_interval(partial(self.__try_next, engine.scan(), self.pb, resolved[0]), 0.1) # explicit delay before each request

    def __try_next(self, engine_gen, pb, self_ip_address, *largs):
      try:
        item = next(engine_gen)
      except StopIteration:
        return False

      pb.value = item.index
      if item.mac_address is not None and str(item.ip_address) != str(self_ip_address):
        next_row_data = [item.ip_address, item.mac_address, "--"]

        self.data_tables.row_data.append(next_row_data)

      return True





if __name__ == "__main__":
  nmap = NMap()
  nmap.run()
