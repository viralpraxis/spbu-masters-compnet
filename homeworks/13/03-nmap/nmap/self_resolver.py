from netifaces import interfaces, ifaddresses, AF_INET
import ipaddress, uuid, socket, re

class SelfResolver():
  def __init__(self, netmask: str) -> None:
    self.netmask = netmask

  def resolve(self):
    return (self.__ipv4_address(), self.__mac_address(), self.__hostname())

  def __ipv4_address(self):
    for interface in interfaces():
      if not AF_INET in ifaddresses(interface):
        continue

      for link in ifaddresses(interface)[AF_INET]:
        ip_address = link["addr"]

        if ipaddress.ip_address(ip_address) not in ipaddress.ip_network(self.netmask, False):
          continue

        return ip_address

  def __mac_address(self):
    return (':'.join(re.findall('..', '%012x' % uuid.getnode()))) # some formatting magic :^)

  def __hostname(self):
    return socket.gethostname()
