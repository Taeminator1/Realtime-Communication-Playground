#!/usr/bin/env python3
"""
UDP Echo Server
- 클라이언트가 보낸 메시지를 그대로 되돌려주는 에코 서버
- connect() 기반 send/recv, sendto() 기반 비연결 전송 모두 지원
- --push 옵션: 등록된 클라이언트에게 일정 간격으로 데이터를 전송
- 기본 포트: 8080
"""

"""
Commands
- 에코: python3 udp_echo_server.py
- 에코 + 주기적 푸시 (1초 간격): python3 udp_echo_server.py --push
- 에코 + 주기적 푸시 (2초 간격): python3 udp_echo_server.py --push --interval 2.0
"""

import socket
import signal
import sys
import argparse
import threading
import time

running = True
registered_clients: set = set()
clients_lock = threading.Lock()


def periodic_sender(server_socket: socket.socket, interval: float):
    """등록된 클라이언트에게 일정 간격으로 데이터를 전송하는 스레드 함수."""
    counter = 0
    while running:
        time.sleep(interval)
        if not running:
            break
        counter += 1
        message = f"서버 푸시 #{counter}"
        data = message.encode("utf-8")
        with clients_lock:
            targets = list(registered_clients)
        for addr in targets:
            try:
                server_socket.sendto(data, addr)
                print(f"[푸시] {addr[0]}:{addr[1]} ← {message}")
            except OSError as e:
                print(f"[오류] {addr[0]}:{addr[1]} — {e}")
                with clients_lock:
                    registered_clients.discard(addr)


def run_server(host: str, port: int, push: bool, interval: float):
    global running

    server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.settimeout(1.0)
    server.bind((host, port))

    mode = "에코 + 푸시" if push else "에코"
    print(f"UDP Echo Server 시작 — {host}:{port} (모드: {mode})")
    if push:
        print(f"푸시 간격: {interval}초")
    print("종료하려면 Ctrl+C를 누르세요.\n")

    def signal_handler(_sig, _frame):
        global running
        print("\n서버를 종료합니다...")
        running = False

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    if push:
        sender_thread = threading.Thread(
            target=periodic_sender, args=(server, interval), daemon=True
        )
        sender_thread.start()

    try:
        while running:
            try:
                data, addr = server.recvfrom(4096)
                if not data:
                    continue
                message = data.decode("utf-8", errors="replace")
                print(f"[수신] {addr[0]}:{addr[1]} → {message}")

                if push:
                    with clients_lock:
                        if addr not in registered_clients:
                            registered_clients.add(addr)
                            print(f"[등록] {addr[0]}:{addr[1]} — 푸시 대상 추가")

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
    parser.add_argument("--push", action="store_true", help="주기적 데이터 푸시 모드 활성화")
    parser.add_argument("--interval", type=float, default=1.0, help="푸시 간격(초) (기본: 1.0)")
    args = parser.parse_args()
    run_server(args.host, args.port, args.push, args.interval)
