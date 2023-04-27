import os

os.environ['KIVY_NO_FILELOG'] = '1'

from kivy.app import App
from kivy.uix.anchorlayout import AnchorLayout
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.clock import Clock

import sys
import logging
import threading
import time
import socket
import argparse
import signal
from functools import partial

class State():
   app = None
   runtime = None

def singal_sigint_handler(sig, frame):
  print("1: exit..")
  State.runtime.notify_exit()
  App.get_running_app().stop()
  print("2: exit..")
  sys.exit(0)


signal.signal(signal.SIGINT, singal_sigint_handler)


class Runtime():
    MSG_NEW = "HELLO"
    MSG_END = "BYE"

    def __init__(self, args) -> None:
        self.args = args
        self.peers = {}
        self.mu = threading.Lock()
        self.running = True
        self.ports_range = (4000, 5000)

    def run(self):
        thr = threading.Thread(target=self.observe_peers_state)
        thr.start()

        udp_thr = threading.Thread(target=self.start_udp_server, args=())
        udp_thr.start()

        broadcast_thr = threading.Thread(target=self.broadcast, args=())
        broadcast_thr.start()

        BroadcastApp().run()

    def notify_exit(self):
        for port in range(self.ports_range[0], self.ports_range[1]):
            self.socket.sendto(bytes(self.MSG_END, "UTF-8"), ("255.255.255.255", port))
        self.running = False
        self.socket.close()

    def observe_peers_state(self):
        while self.running:
          logging.info("observing state..")
          current_time = time.monotonic()
          to_remove = []

          self.mu.acquire()

          for key, value in self.peers.items():
              if current_time - value > self.args.inactive_peer_period:
                  to_remove.append(key)

          if len(to_remove) > 0:
            logging.info(f"going to remove {len(to_remove)} peers")

            for item_to_remove in to_remove:
              del self.peers[item_to_remove]

          self.mu.release()

          Clock.schedule_once(partial(self.update_ui, self))

          logging.info(self.peers)
          time.sleep(3)

    def update_ui(self, value, *largs):
        output = f"peers ({len(self.peers.keys())}):\n"
        for key in self.peers:
            output += str(key) + "\n"

        logging.info("updated UI")
        logging.info(len(self.peers.keys()))

        if State.app and State.app.data_field:
            State.app.data_field.text = output

    # NOTE: It was not specified that we have to use raw IP broadcast packets.
    # So the current approch is to simply send messages via UDP broadcast to port range
    def start_udp_server(self):
        self.socket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM, proto=socket.IPPROTO_UDP)
        self.socket.bind(("0.0.0.0", self.args.port))
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

        logging.info(f"ready to receive on {self.args.port}")

        while(self.running):
            bytesAddressPair = self.socket.recvfrom(32)
            message = bytesAddressPair[0]
            address = bytesAddressPair[1]

            if address[1] == self.args.port: # skip datagrams sent by itself
                continue

            clientMsg = "Message from Client:{}".format(message)
            clientIP  = "Client IP Address:{}".format(address)
            decodedMsg = message.decode('UTF-8')
            logging.info(f"recevied {clientMsg} from {clientIP}")

            if decodedMsg == self.MSG_NEW:
                self.mu.acquire()
                self.peers[address] = time.monotonic()
                self.mu.release()
            elif decodedMsg == self.MSG_END:
                self.mu.acquire()
                if address in self.peers:
                    del self.peers[address]
                self.mu.release()
            else:
                logging.error("Unexpected message from peer")

    def broadcast(self):
        while self.running:
            for port in range(self.ports_range[0], self.ports_range[1]):
                self.socket.sendto(bytes(self.MSG_NEW, "UTF-8"), ("255.255.255.255", port))
            logging.info("sent broadcast UDP message")

            time.sleep(self.args.broadcast_period)


class GUI(AnchorLayout):
    def __init__(self, **kwargs):
        super(GUI, self).__init__(**kwargs)
        self.data_field = TextInput(multiline=True, text="")

        self.add_widget(self.data_field)

class BroadcastApp(App):
    def build(self):
        gui = GUI()
        State.app = gui

        return gui

parser = argparse.ArgumentParser(
                    prog='broad.py',
                    description='broadcast p2p protocol',
                    )

parser.add_argument("-p", "--port", type=int, required=True)
parser.add_argument("-t", "--broadcast-period", type=float, default=3)
parser.add_argument("-d", "--inactive-peer-period", type=float, default=12)

if __name__ == '__main__':
    State.runtime = Runtime(parser.parse_args())

    State.runtime.run()
