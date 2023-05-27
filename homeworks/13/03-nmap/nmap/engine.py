import ipaddress
import arpreq
import time
from dataclasses import dataclass

class Engine():
  @dataclass
  class ScanResultEntry:
    index: int
    total_count: int
    ip_address: str
    mac_address: str

  def __init__(self, netmask: str) -> None:
    self.netmask = netmask
    self.ip_addresses = ipaddress.ip_network(self.netmask, False)
    self.total = len(list(self.ip_addresses))

  def scan(self):
    for (index, ip_address) in enumerate(self.ip_addresses):
      mac_address = self.__ping_ip_address(ip_address)

      yield Engine.ScanResultEntry(
        index=index + 1,
        total_count=self.total,
        ip_address=ip_address,
        mac_address=mac_address
      )

  def __ping_ip_address(self, ip_address: str):
    macaddr = arpreq.arpreq(ip_address)
    return macaddr
