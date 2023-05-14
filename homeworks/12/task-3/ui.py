from kivy.metrics import dp
from kivy.uix.gridlayout import GridLayout
from kivy.uix.boxlayout import BoxLayout

from kivy.uix.button import Button
from kivymd.app import MDApp
from kivymd.uix.datatables import MDDataTable
from kivy.uix.textinput import TextInput

from forwarder import *

import threading

class PortForwarder(MDApp):
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Orange"

        self.button = Button(text="AddRow", size_hint_y=None, pos_hint={"bottom": 0})
        self.button.bind(texture_size=self.button.setter("size"))

        self.textinput_title = TextInput(text="Title", multiline=False)
        self.textinput_localIP = TextInput(text="Local IP", multiline=False)
        self.textinput_localPort = TextInput(text="Local port", multiline=False)
        self.textinput_remoteIP = TextInput(text="Remote IP", multiline=False)
        self.textinput_remotePort = TextInput(text="Remote port", multiline=False)

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
                ("Title", dp(20)),
                ("Local IP", dp(30)),
                ("Local port", dp(50)),
                ("Remote IP", dp(30)),
                ("Remote port", dp(30)),
            ],
            row_data = data
        )

        self.control_layout.add_widget(self.button)
        self.control_layout.add_widget(self.textinput_title)
        self.control_layout.add_widget(self.textinput_localIP)
        self.control_layout.add_widget(self.textinput_localPort)
        self.control_layout.add_widget(self.textinput_remoteIP)
        self.control_layout.add_widget(self.textinput_remotePort)

    def on_start(self):
        self.button.bind(on_press=lambda x: self.addrow())

    def addrow(self):
        current_local_ip = self.textinput_localIP.text
        current_local_port = int(self.textinput_localPort.text)
        current_remote_ip = self.textinput_remoteIP.text
        current_remote_port = int(self.textinput_remotePort.text)

        new_row_data = [
          self.textinput_title.text,
          current_local_ip,
          current_local_port,
          current_remote_ip,
          current_remote_port
        ]
        self.data_tables.row_data.append(new_row_data)

        thrd = threading.Thread(target=self.forward, args=(current_local_ip, current_local_port, current_remote_ip, current_remote_port,))
        thrd.start()

    def forward(self, local_ip, local_port, remote_ip, remote_port):
      f = Engine(local_ip, local_port, remote_ip, remote_port)
      f.run()


PortForwarder().run()
