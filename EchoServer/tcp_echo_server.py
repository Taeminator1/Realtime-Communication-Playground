#!/usr/bin/env python3
"""
TCP Echo Server
- 클라이언트가 보낸 메시지를 그대로 되돌려주는 에코 서버
- 여러 클라이언트를 동시에 처리 (스레딩)
- 기본 포트: 8080
"""

import socket
import threading
import signal
import sys
import argparse

shutdown_event = threading.Event()


def handle_client(conn: socket.socket, addr: tuple):
    print(f"[연결] {addr[0]}:{addr[1]}")
    try:
        while not shutdown_event.is_set():
            data = conn.recv(4096)
            if not data:
                break
            message = data.decode("utf-8", errors="replace")
            print(f"[수신] {addr[0]}:{addr[1]} → {message}")
            conn.sendall(data)
            print(f"[에코] {addr[0]}:{addr[1]} ← {message}")
    except (ConnectionResetError, BrokenPipeError):
        pass
    except OSError:
        pass
    finally:
        conn.close()
        print(f"[종료] {addr[0]}:{addr[1]}")


def run_server(host: str, port: int):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.settimeout(1.0)
    server.bind((host, port))
    server.listen(5)
    print(f"TCP Echo Server 시작 — {host}:{port}")
    print("종료하려면 Ctrl+C를 누르세요.\n")

    def signal_handler(_sig, _frame):
        print("\n서버를 종료합니다...")
        shutdown_event.set()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    threads: list[threading.Thread] = []
    try:
        while not shutdown_event.is_set():
            try:
                conn, addr = server.accept()
                t = threading.Thread(target=handle_client, args=(conn, addr), daemon=True)
                t.start()
                threads.append(t)
            except socket.timeout:
                continue
    finally:
        server.close()
        for t in threads:
            t.join(timeout=2)
        print("서버가 종료되었습니다.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="TCP Echo Server")
    parser.add_argument("--host", default="0.0.0.0", help="바인드 주소 (기본: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=8080, help="포트 번호 (기본: 8080)")
    args = parser.parse_args()
    run_server(args.host, args.port)
