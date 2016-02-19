import socket
import base64
import httplib
from threading import Thread
import re
import signal
import os
import sys
import json

defaultIP = '8.8.8.8'

# import sys
# sys.stdout = open('./log/DNS.log', 'w+')


class DNSQuery:

	def __init__(self, data, addr):
		self.data = data
		self.addr = addr
		self.dominio = ''
		self.ip = defaultIP

		tipo = (ord(data[2]) >> 3) & 15   # Opcode bits
		if tipo == 0:                     # Standard query
			ini = 12
			lon = ord(data[ini])
			while lon != 0:
				self.dominio += data[ini + 1:ini + lon + 1] + '.'
				ini += lon + 1
				lon = ord(data[ini])
		if len(self.dominio) > 1:
			self.dominio = self.dominio[0:-1]


def respuesta(query):
	stat = 2

	if dnsCache.__contains__(query.dominio):
		query.ip = dnsCache[query.dominio]
	else:
		if len(query.dominio.split('.')) < 2:
			return
		query.dominio = query.dominio.replace('_', '')
		if query.dominio.lower()[-11:] == 'dns-api.org':
			query.ip = '80.68.84.120'
			stat = 0
		else:
			try:
				# print query.dominio

				dnsConn = httplib.HTTPSConnection('dns-api.org', timeout=15)
				dnsConn.request("GET", "/A/" + query.dominio)

				dnsRes = dnsConn.getresponse()
				jsonRes = json.loads(dnsRes.read())
				query.ip = jsonRes[0]['value']

				if dnsRes.status == 200:
					stat = 1
				else:
					pass
			except:
				print '{:5s}  {:25s} {:15s}'.format('Exc', str(query.ip), str(query.dominio))
				return

			# add to dns cache
			if re.match('[0-9]+\.[0-9]+\.[0-9]+\.[0-9]', query.ip) and not query.ip == defaultIP:
				dnsCache[query.dominio] = query.ip
			else:
				print '{:5s}  {:15s} {:15s}'.format('Err', str(query.dominio), query.ip)
				return

	packet = ''
	if query.dominio:
		packet += query.data[:2] + "\x81\x80"
		# Questions and Answers Counts
		packet += query.data[4:6] + query.data[4:6] + '\x00\x00\x00\x00'
		# Original Domain Name Question
		packet += query.data[12:]
		# Pointer to domain name
		packet += '\xc0\x0c'
		# Response type, ttl and resource data length -> 4 bytes
		packet += '\x00\x01\x00\x01\x00\x00\x00\x3c\x00\x04'
		# 4bytes of IP
		packet += str.join('', map(lambda x: chr(int(x)), query.ip.split('.')))

	udps.sendto(packet, query.addr)

	if stat == 1:
		print '{:5s}  {:15s} {:15s}'.format(str(dnsRes.status), str(query.ip), str(query.dominio))
		pass
	elif stat == 2 and not query.dominio == 'dns-api.org':
		print '{:5s}  {:20s} {:15s}'.format('Hit', str(query.ip), str(query.dominio))
		pass

def signal_term_handler(signal, frame):
	print 'SIGTERM'
	udps.close()
	sys.exit(0)

def writePidFile():
	pid = str(os.getpid())
	f = open(sys.argv[1], 'w')
	f.write(pid)
	f.close()

if __name__ == '__main__':

	signal.signal(signal.SIGTERM, signal_term_handler)
	signal.signal(signal.SIGINT, signal_term_handler)

	writePidFile()
	print 'DNS server running on port 7613.'

	udps = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	udps.bind(("0.0.0.0", 7613))

	dnsCache = dict()
	try:
		a = file('/etc/iitg-tproxy/extra/defaultIPs', 'r')
		for i in a:
			line_ip = re.split("[, \-!?:\t\n]+", i)
			dnsCache[line_ip[1]] = line_ip[0]
		a.close()
		print 'Default IPs loaded'
	except:
		print 'Could not load default IPs'

	try:
		while 1:
			data, addr = udps.recvfrom(1024)
			p = DNSQuery(data, addr)
			t = Thread(target=respuesta, args=(p,))
			t.start()
	except (KeyboardInterrupt, SystemExit):
		print 'Finalizing'

		udps.close()
		sys.exit(0)
