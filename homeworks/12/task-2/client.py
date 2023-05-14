from kivy.metrics import dp
from kivy.uix.gridlayout import GridLayout
from kivy.uix.boxlayout import BoxLayout

from kivy.uix.button import Button
from kivymd.app import MDApp
from kivymd.uix.datatables import MDDataTable
from kivy.uix.textinput import TextInput

import random
import string
import socket
import time

class Engine():
    def __init__(self, protocol, ip, port, packets) -> None:
        self.protocol = protocol
        self.ip = ip
        self.port = port
        self.packets = packets

    def start(self):
        if self.protocol == "TCP":
            self.__start_tcp()
        elif self.protocol == "UDP":
            self.__start_udp()

    def __start_tcp(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.connect((self.ip, self.port))

        for i in range(self.packets):
            print(f"Send iteration {i}")
            data = ""
            data = data + self.__random_payload(2**10)
            data = data + " " + str(i + 1)
            data = data + " " + str(self.packets)
            data = data + " " + str(self.__current_timestamp_monotonic_ms())

            self.sock.send(data.encode())

        self.sock.send("END".encode())
        self.sock.close()

    def __start_udp(self):
        self.sock = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)

        for i in range(self.packets):
            print(f"Send iteration {i}")
            data = ""
            data = data + self.__random_payload(2**10)
            data = data + " " + str(i + 1)
            data = data + " " + str(self.packets)
            data = data + " " + str(self.__current_timestamp_monotonic_ms())

            self.sock.sendto(data.encode(), (self.ip, self.port))

        self.sock.sendto("END".encode(), (self.ip, self.port))
        self.sock.close()

    def __random_payload(self, length: int):
        return "".join(random.choice(string.ascii_lowercase) for i in range(length))

    def __current_timestamp_monotonic_ms(self):
        return int(time.monotonic() * 1000)

class Client(MDApp):
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Orange"

        self.button = Button(text="Start", size_hint_y=None, pos_hint={"bottom": 0})
        self.button.bind(texture_size=self.button.setter("size"))

        self.textinput_protocol = TextInput(text="Protocol", multiline=False)
        self.textinput_remoteIP = TextInput(text="Remote IP", multiline=False)
        self.textinput_remotePort = TextInput(text="Remote port", multiline=False)
        self.textinput_packets = TextInput(text="Packets", multiline=False)

        self.rowcount = 0
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
                ("Index", dp(20)),
                ("Protocol", dp(40)),
                ("IP address", dp(30)),
                ("Port", dp(50)),
                ("Packets", dp(30)),
            ],
            row_data = data
        )

        self.control_layout.add_widget(self.button)
        self.control_layout.add_widget(self.textinput_protocol)
        self.control_layout.add_widget(self.textinput_remoteIP)
        self.control_layout.add_widget(self.textinput_remotePort)
        self.control_layout.add_widget(self.textinput_packets)

    def on_start(self):
        self.button.bind(on_press=lambda x: self.addrow())

    def addrow(self):
        self.rowcount += 1

        current_protocol = self.textinput_protocol.text
        current_remote_ip = self.textinput_remoteIP.text
        current_remote_port = int(self.textinput_remotePort.text)
        current_packets = int(self.textinput_packets.text)

        new_row_data = [
          self.rowcount,
          current_protocol,
          current_remote_ip,
          current_remote_port,
          current_packets
        ]

        self.data_tables.row_data.append(new_row_data)
        self.start(current_protocol, current_remote_ip, current_remote_port, current_packets)

    def start(self, protocol, remote_ip, remote_port, packets):
      engine = Engine(protocol, remote_ip, remote_port, packets)

      engine.start()


Client().run()
