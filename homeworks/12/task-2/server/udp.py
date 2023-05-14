from kivy.metrics import dp
from kivy.uix.gridlayout import GridLayout
from kivy.uix.boxlayout import BoxLayout

from kivy.uix.button import Button
from kivymd.app import MDApp
from kivymd.uix.datatables import MDDataTable
from kivy.uix.textinput import TextInput

import socket
import threading
import time

class Engine():
    def __init__(self, ip, port, runtime) -> None:
        self.ip = ip
        self.port = port
        self.runtime = runtime

    def start(self):
        self.sock = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
        self.sock.bind((self.ip, self.port))

        self.total_bytes_received = 0
        self.received = 0
        self.total = 0
        self.first_sent_ts = None
        self.last_received_ts = None

        self.__process_socket(self.sock)
        self.runtime.addrow(self.total_bytes_received, self.received, self.total, self.last_received_ts - self.first_sent_ts)

    def __process_socket(self, sock):
        while True:
            data, _ = sock.recvfrom(2**11)
            data = data.decode("UTF-8")
            if data == "END": break
            if len(data) == 0: break

            print("received: " + str(self.received))

            items = data.split(" ")

            self.total_bytes_received += len(data)
            self.received += 1
            self.total = int(items[2])
            if self.first_sent_ts is None:
              self.first_sent_ts = int(items[3])
            self.last_received_ts = self.__current_timestamp_monotonic_ms()

        print(self.total_bytes_received)
        print(self.last_received_ts - self.first_sent_ts)
        sock.close()


    def __current_timestamp_monotonic_ms(self):
        return int(time.monotonic() * 1000)

class UDPServer(MDApp):
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Orange"

        self.button = Button(text="Start", size_hint_y=None, pos_hint={"bottom": 0})
        self.button.bind(texture_size=self.button.setter("size"))

        self.textinput_localIP = TextInput(text="Local IP", multiline=False)
        self.textinput_localPort = TextInput(text="Local port", multiline=False)

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
                ("IP address", dp(30)),
                ("Port", dp(50)),
                ("Packets", dp(30)),
                ("Speed", dp(30)),
            ],
            row_data = data
        )

        self.control_layout.add_widget(self.button)
        self.control_layout.add_widget(self.textinput_localIP)
        self.control_layout.add_widget(self.textinput_localPort)

    def on_start(self):
        self.button.bind(on_press=lambda x: self.runthread())

    def runthread(self):
        current_local_ip = self.textinput_localIP.text
        current_local_port = int(self.textinput_localPort.text)

        thrd = threading.Thread(target=self.start, args=(current_local_ip, current_local_port))
        thrd.start()

    def addrow(self, total_bytes, received_packets, total_packets, time_total):
        current_local_ip = self.textinput_localIP.text
        current_local_port = int(self.textinput_localPort.text)

        new_row_data = [
          self.rowcount,
          current_local_ip,
          current_local_port,
          str(received_packets) + "/" + str(total_packets),
          self.format_speed(time_total, total_bytes)
        ]

        self.data_tables.row_data.append(new_row_data)

    def format_speed(self, time_total, bytes_total):
      result = ""

      if bytes_total > 1024:
        result = result + str(round(float(bytes_total) / 1024, 2)) + "KB"
      else:
        result = result + str(bytes_total) + "B"

      result += " / " + str(time_total) + "ms"

      return result

    def start(self, ip, port):
      Engine(ip, port, self).start()


UDPServer().run()
