#!/usr/bin/env python3
"""
UDP Echo Server
- 클라이언트가 보낸 메시지를 그대로 되돌려주는 에코 서버
- connect() 기반 send/recv, sendto() 기반 비연결 전송 모두 지원
- 기본 포트: 8080
"""

import socket
import signal
import sys
import argparse

running = True


def run_server(host: str, port: int):
    global running

    server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.settimeout(1.0)
    server.bind((host, port))
    print(f"UDP Echo Server 시작 — {host}:{port}")
    print("종료하려면 Ctrl+C를 누르세요.\n")

    def signal_handler(_sig, _frame):
        global running
        print("\n서버를 종료합니다...")
        running = False

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        while running:
            try:
                data, addr = server.recvfrom(4096)
                if not data:
                    continue
                message = data.decode("utf-8", errors="replace")
                print(f"[수신] {addr[0]}:{addr[1]} → {message}")
                server.sendto(data, addr)
                print(f"[에코] {addr[0]}:{addr[1]} ← {message}")
            except socket.timeout:
                continue
    finally:
        server.close()
        print("서버가 종료되었습니다.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UDP Echo Server")
    parser.add_argument("--host", default="0.0.0.0", help="바인드 주소 (기본: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=8080, help="포트 번호 (기본: 8080)")
    args = parser.parse_args()
    run_server(args.host, args.port)
