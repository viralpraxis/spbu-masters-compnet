class Presenter():
    def __init__(self):
      self._frame = None

    def present(self, frame) -> str:
      self._frame = frame
      self.ip_src = None
      self.ip_dest = None
      self.port_src = None
      self.port_dest = None
      self.len = None

      return self._extract_protocol_info()

    def _extract_protocol_info(self) -> None:
        chunks = []

        for proto in self._frame.protocol_queue:
            try:
                chunks.append(getattr(self, f"_extract_{proto.lower()}_data")())
            except AttributeError as e:
                chunks.append("Unknown protocol")
                pass

        return (self.ip_src, self.ip_dest, self.port_src, self.port_dest, self.len, "\n---\n".join(chunks))

    def _extract_ethernet_data(self) -> str:
      return "PROTOCOL: ethernet"

    def _extract_ethernet_data(self) -> str:
        ethernet = self._frame.ethernet

        return f"PROTOCOL: ethernet\n src: {ethernet.src}\n dest: {ethernet.dst}\n len: {self._frame.frame_length}\n epoch: {self._frame.epoch_time}"

    def _extract_ipv4_data(self) -> str:
        ipv4 = self._frame.ipv4

        self.ip_src = ipv4.src
        self.ip_dest = ipv4.dst
        self.len = ipv4.len

        return f"PROTOCOL: ipv4\n src: {ipv4.src}\n dest: {ipv4.dst}\n len: {ipv4.len}\n ttl: {ipv4.ttl}\n chechsum: {ipv4.chksum_hex_str}"

    def _extract_ipv6_data(self) -> str:
        ipv6 = self._frame.ipv6

        return f"PROTOCOL: ipv6\n src: {ipv6.src}\n dest: {ipv6}.dst\n len: {ipv6.payload_len}"

    def _extract_tcp_data(self) -> str:
        tcp = self._frame.tcp

        self.port_src = tcp.sport
        self.port_dest = tcp.dport

        return f"PROTOCOL: TCP\n src port: {tcp.sport}\n dest port: {tcp.dport}\n seqnum: {tcp.seq}\n window: {tcp.window}"

    def _extract_udp_data(self) -> str:
        udp = self._frame.udp

        return f"PROTOCOL: UDP\n length: {udp.len}\n checksum: {udp.chksum}"
