import socket
import select
import time

class Client:
    def __init__(self):
        self.forward = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def start(self, host, port):
        self.forward.connect((host, port))
        return self.forward

class Engine:
    input_list = []
    channel = {}

    def __init__(self, host, port, remote_host, remote_port):
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        self.server.bind((host, port))
        self.server.listen(200)

        self.remote_host = remote_host
        self.remote_port = remote_port

    def run(self):
        self.input_list.append(self.server)

        while True:
            time.sleep(0.0001)

            input_chan, _, _ = select.select(self.input_list, [], [])
            for self.s in input_chan:
                if self.s == self.server:
                    self.on_accept()
                    break

                self.data = self.s.recv(4096)

                if len(self.data) == 0:
                    self.on_close()
                    break
                else:
                    self.on_recv()

    def on_accept(self):
        client = Client().start(self.remote_host, self.remote_port)

        client_socket, _ = self.server.accept()

        if client:
            self.input_list.append(client_socket)
            self.input_list.append(client)

            self.channel[client_socket] = client
            self.channel[client] = client_socket
        else:
            client_socket.close()

    def on_close(self):
        self.input_list.remove(self.s)
        self.input_list.remove(self.channel[self.s])
        out = self.channel[self.s]

        self.channel[out].close()
        self.channel[self.s].close()

        del self.channel[out]
        del self.channel[self.s]

    def on_recv(self):
        self.channel[self.s].send(self.data)
