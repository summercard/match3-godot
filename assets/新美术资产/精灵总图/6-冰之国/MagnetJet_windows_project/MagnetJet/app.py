from __future__ import annotations

import json
import random
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

from PySide6.QtCore import QSettings, QStandardPaths, QTimer, Qt, QUrl
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import (
    QApplication,
    QFileDialog,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QProgressBar,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

try:
    import libtorrent as lt
except ImportError as exc:  # pragma: no cover - only used when the dependency is missing
    lt = None  # type: ignore[assignment]
    LIBTORRENT_IMPORT_ERROR = exc
else:
    LIBTORRENT_IMPORT_ERROR = None


APP_NAME = "MagnetJet"
APP_VERSION = "1.0.0"


@dataclass
class Snapshot:
    name: str
    state: str
    progress: float
    downloaded: int
    total: int
    download_rate: int
    upload_rate: int
    peers: int
    seeds: int
    paused: bool
    completed: bool
    error: str = ""


def format_bytes(value: int | float) -> str:
    """Format a byte quantity for display."""
    value = max(0, float(value))
    units = ("B", "KB", "MB", "GB", "TB")
    unit_index = 0
    while value >= 1024 and unit_index < len(units) - 1:
        value /= 1024
        unit_index += 1
    if unit_index == 0:
        return f"{int(value)} {units[unit_index]}"
    return f"{value:.2f} {units[unit_index]}"


def format_speed(value: int | float) -> str:
    return f"{format_bytes(value)}/s"


def is_magnet_uri(value: str) -> bool:
    return value.strip().lower().startswith("magnet:?xt=urn:btih:")


def state_name(state: int) -> str:
    # torrent_status.state_t enum order in libtorrent 2.x
    names = (
        "等待检查",
        "检查文件",
        "获取元数据",
        "正在下载",
        "下载完成",
        "正在做种",
        "分配磁盘空间",
        "检查恢复数据",
    )
    return names[state] if 0 <= state < len(names) else "准备中"


class DownloadEngine:
    """A deliberately small, single-task libtorrent wrapper."""

    def __init__(self, data_dir: Path) -> None:
        if lt is None:
            raise RuntimeError("未找到 libtorrent。请先运行：pip install -r requirements.txt")

        self.data_dir = data_dir
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.task_file = self.data_dir / "last_task.json"
        self.resume_file = self.data_dir / "last_task.fastresume"
        self.config_file = self.data_dir / "config.json"

        self.listen_port = self._load_or_create_port()
        self.session = self._create_session()
        self.handle: Optional[Any] = None
        self.current_magnet = ""
        self.current_path = ""
        self.last_error = ""
        self.completed = False

    def _load_or_create_port(self) -> int:
        try:
            payload = json.loads(self.config_file.read_text(encoding="utf-8"))
            port = int(payload.get("listen_port", 0))
            if 49152 <= port <= 65535:
                return port
        except (FileNotFoundError, ValueError, OSError, json.JSONDecodeError):
            pass

        port = random.randint(49152, 65535)
        self.config_file.write_text(
            json.dumps({"listen_port": port}, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        return port

    def _create_session(self) -> Any:
        # These settings are applied before the session starts. Keeping one stable
        # listening port helps peers and DHT nodes reconnect on later launches.
        settings = {
            "user_agent": f"{APP_NAME}/{APP_VERSION}",
            "listen_interfaces": f"0.0.0.0:{self.listen_port},[::]:{self.listen_port}",
            "enable_dht": True,
            "enable_lsd": True,
            "enable_upnp": True,
            "enable_natpmp": True,
            "enable_outgoing_tcp": True,
            "enable_incoming_tcp": True,
            "enable_outgoing_utp": True,
            "enable_incoming_utp": True,
            "connections_limit": 800,
            "connection_speed": 60,
            "torrent_connect_boost": 100,
            "max_peerlist_size": 5000,
            "dht_bootstrap_nodes": (
                "dht.libtorrent.org:25401,"
                "router.bittorrent.com:6881,"
                "dht.transmissionbt.com:6881"
            ),
        }
        try:
            return lt.session(settings)
        except TypeError:
            # Compatibility fallback for older bindings.
            session = lt.session()
            session.apply_settings(settings)
            return session

    def has_task(self) -> bool:
        try:
            return self.handle is not None and bool(self.handle.is_valid())
        except Exception:
            return False

    def _storage_params(self, save_path: str) -> dict[str, Any]:
        params: dict[str, Any] = {"save_path": save_path}
        try:
            params["storage_mode"] = lt.storage_mode_t.storage_mode_sparse
        except AttributeError:
            pass
        return params

    def start_new(self, magnet: str, save_path: str) -> None:
        if not is_magnet_uri(magnet):
            raise ValueError("磁力链接格式不正确。链接需要以 magnet:?xt=urn:btih: 开头。")
        if not save_path:
            raise ValueError("请先选择下载文件夹。")

        path = Path(save_path).expanduser()
        path.mkdir(parents=True, exist_ok=True)

        if self.has_task():
            self.remove_task()

        self.current_magnet = magnet.strip()
        self.current_path = str(path)
        self.last_error = ""
        self.completed = False
        self.handle = lt.add_magnet_uri(
            self.session,
            self.current_magnet,
            self._storage_params(self.current_path),
        )
        # The Python binding starts new magnet tasks paused by default.
        self.handle.resume()
        self._write_task_metadata(paused=False)

        # Request tracker announcements as soon as the metadata task enters
        # the engine. Errors here are non-fatal; DHT / PEX still work.
        try:
            self.handle.force_reannounce()
        except Exception:
            pass

    def restore_last_task(self) -> bool:
        """Restore the prior unfinished task, keeping it paused after app launch."""
        if not self.task_file.exists():
            return False

        try:
            task = json.loads(self.task_file.read_text(encoding="utf-8"))
            magnet = str(task["magnet"])
            save_path = str(task["save_path"])
            if not is_magnet_uri(magnet) or not save_path:
                raise ValueError("无效的已保存任务")

            self.current_magnet = magnet
            self.current_path = save_path
            self.completed = False

            restored = False
            if self.resume_file.exists():
                try:
                    params = lt.read_resume_data(self.resume_file.read_bytes())
                    params.save_path = save_path
                    self.handle = self.session.add_torrent(params)
                    restored = True
                except Exception:
                    # The partial data stays on disk; the magnet fallback below
                    # will safely re-check anything that is already present.
                    restored = False

            if not restored:
                self.handle = lt.add_magnet_uri(
                    self.session,
                    magnet,
                    self._storage_params(save_path),
                )

            self.handle.pause()
            return True
        except Exception:
            self.clear_saved_task()
            self.handle = None
            self.current_magnet = ""
            self.current_path = ""
            return False

    def resume(self) -> None:
        if not self.has_task():
            return
        self.completed = False
        self.last_error = ""
        self.handle.resume()
        self._write_task_metadata(paused=False)
        try:
            self.handle.force_reannounce()
        except Exception:
            pass

    def pause(self) -> None:
        if not self.has_task() or self.completed:
            return
        self.handle.pause()
        self._write_task_metadata(paused=True)

    def remove_task(self) -> None:
        """Remove the torrent from the engine without deleting downloaded files."""
        if self.has_task():
            try:
                self.session.remove_torrent(self.handle)
            except Exception:
                pass
        self.handle = None
        self.current_magnet = ""
        self.current_path = ""
        self.last_error = ""
        self.completed = False
        self.clear_saved_task()

    def _write_task_metadata(self, paused: bool) -> None:
        if not self.current_magnet or not self.current_path or self.completed:
            return
        payload = {
            "magnet": self.current_magnet,
            "save_path": self.current_path,
            "paused": paused,
            "saved_at": int(time.time()),
        }
        self.task_file.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )

    def clear_saved_task(self) -> None:
        for file_path in (self.task_file, self.resume_file):
            try:
                file_path.unlink()
            except FileNotFoundError:
                pass
            except OSError:
                pass

    def _drain_alerts(self) -> None:
        try:
            alerts = self.session.pop_alerts()
        except Exception:
            return

        for alert in alerts:
            try:
                alert_type = alert.what()
            except Exception:
                alert_type = ""

            # Tracker errors are usually temporary and should not interrupt a
            # magnet that is still discovering peers via DHT/PEX.
            if alert_type in {"torrent_error", "metadata_failed", "file_error"}:
                try:
                    self.last_error = alert.message()
                except Exception:
                    self.last_error = "下载引擎报告了一个错误。"

    def snapshot(self) -> Optional[Snapshot]:
        self._drain_alerts()
        if not self.has_task():
            return None

        try:
            status = self.handle.status()
            is_seeding = bool(getattr(status, "is_seeding", False))
            paused = bool(getattr(status, "paused", False))

            if is_seeding:
                self.completed = True
                if not paused:
                    # This app is download-focused. Stop automatically after
                    # verification finishes instead of silently consuming upload.
                    self.handle.pause()
                    paused = True
                self.clear_saved_task()

            name = str(getattr(status, "name", "") or "正在获取元数据…")
            state = "下载完成" if self.completed else state_name(int(status.state))
            return Snapshot(
                name=name,
                state=state,
                progress=min(100.0, max(0.0, float(status.progress) * 100.0)),
                downloaded=int(getattr(status, "total_wanted_done", 0)),
                total=int(getattr(status, "total_wanted", 0)),
                download_rate=int(getattr(status, "download_rate", 0)),
                upload_rate=int(getattr(status, "upload_rate", 0)),
                peers=int(getattr(status, "num_peers", 0)),
                seeds=int(getattr(status, "num_seeds", 0)),
                paused=paused,
                completed=self.completed,
                error=self.last_error,
            )
        except Exception as exc:
            self.last_error = str(exc)
            return Snapshot(
                name="任务状态读取失败",
                state="错误",
                progress=0.0,
                downloaded=0,
                total=0,
                download_rate=0,
                upload_rate=0,
                peers=0,
                seeds=0,
                paused=True,
                completed=False,
                error=self.last_error,
            )

    def _save_resume_data(self) -> None:
        if not self.has_task() or self.completed:
            return

        try:
            self.handle.save_resume_data()
            deadline = time.monotonic() + 1.5
            while time.monotonic() < deadline:
                for alert in self.session.pop_alerts():
                    try:
                        alert_type = alert.what()
                    except Exception:
                        alert_type = ""
                    if alert_type == "save_resume_data":
                        data = lt.write_resume_data_buf(alert.params)
                        self.resume_file.write_bytes(bytes(data))
                        return
                time.sleep(0.05)
        except Exception:
            # The raw partial files remain usable even if resume-data writing
            # fails, so shutdown must not be blocked by this best-effort step.
            return

    def shutdown(self) -> None:
        if self.has_task() and not self.completed:
            try:
                paused = bool(self.handle.status().paused)
            except Exception:
                paused = True
            self._write_task_metadata(paused=paused)
            self._save_resume_data()
        try:
            if hasattr(self.session, "abort"):
                self.session.abort()
            else:
                self.session.pause()
                for stop_method in ("stop_dht", "stop_lsd", "stop_upnp", "stop_natpmp"):
                    method = getattr(self.session, stop_method, None)
                    if method is not None:
                        method()
        except Exception:
            pass


class MainWindow(QMainWindow):
    def __init__(self, engine: DownloadEngine) -> None:
        super().__init__()
        self.engine = engine
        self.settings = QSettings("MagnetJet", "MagnetJet")

        self.setWindowTitle(f"{APP_NAME} · 极速磁链下载")
        self.setMinimumSize(760, 510)
        self.resize(820, 560)

        self._build_ui()
        self._restore_window_state()
        self._restore_last_task()

        self.timer = QTimer(self)
        self.timer.timeout.connect(self.refresh_status)
        self.timer.start(500)
        self.refresh_status()

    def _build_ui(self) -> None:
        central = QWidget(self)
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(28, 24, 28, 24)
        layout.setSpacing(14)

        title = QLabel("极速磁链下载")
        title_font = title.font()
        title_font.setPointSize(title_font.pointSize() + 7)
        title_font.setBold(True)
        title.setFont(title_font)
        layout.addWidget(title)

        subtitle = QLabel(
            "粘贴磁力链接，选择保存位置后即可下载。未完成任务会在下次启动时保留。"
        )
        subtitle.setWordWrap(True)
        layout.addWidget(subtitle)

        magnet_label = QLabel("磁力链接")
        layout.addWidget(magnet_label)
        self.magnet_edit = QLineEdit()
        self.magnet_edit.setPlaceholderText("magnet:?xt=urn:btih:...")
        self.magnet_edit.setClearButtonEnabled(True)
        layout.addWidget(self.magnet_edit)

        folder_label = QLabel("保存文件夹")
        layout.addWidget(folder_label)
        folder_row = QHBoxLayout()
        self.folder_edit = QLineEdit()
        self.folder_edit.setReadOnly(True)
        self.folder_edit.setPlaceholderText("请选择下载文件夹")
        self.choose_folder_button = QPushButton("选择文件夹…")
        self.choose_folder_button.clicked.connect(self.choose_folder)
        folder_row.addWidget(self.folder_edit, 1)
        folder_row.addWidget(self.choose_folder_button)
        layout.addLayout(folder_row)

        control_row = QHBoxLayout()
        self.start_button = QPushButton("开始下载")
        self.start_button.clicked.connect(self.start_or_resume)
        self.pause_button = QPushButton("暂停")
        self.pause_button.clicked.connect(self.pause_download)
        self.new_task_button = QPushButton("新建任务")
        self.new_task_button.clicked.connect(self.new_task)
        self.open_folder_button = QPushButton("打开文件夹")
        self.open_folder_button.clicked.connect(self.open_folder)
        control_row.addWidget(self.start_button)
        control_row.addWidget(self.pause_button)
        control_row.addWidget(self.new_task_button)
        control_row.addStretch(1)
        control_row.addWidget(self.open_folder_button)
        layout.addLayout(control_row)

        line = QFrame()
        line.setFrameShape(QFrame.Shape.HLine)
        line.setFrameShadow(QFrame.Shadow.Sunken)
        layout.addWidget(line)

        self.file_name_label = QLabel("尚未开始下载")
        file_font = self.file_name_label.font()
        file_font.setBold(True)
        self.file_name_label.setFont(file_font)
        self.file_name_label.setWordWrap(True)
        layout.addWidget(self.file_name_label)

        self.state_label = QLabel("状态：准备就绪")
        layout.addWidget(self.state_label)

        self.progress = QProgressBar()
        self.progress.setRange(0, 1000)
        self.progress.setValue(0)
        self.progress.setTextVisible(False)
        layout.addWidget(self.progress)

        self.progress_label = QLabel("0.0%")
        self.progress_label.setAlignment(Qt.AlignmentFlag.AlignRight)
        layout.addWidget(self.progress_label)

        stats = QGridLayout()
        stats.setHorizontalSpacing(20)
        stats.setVerticalSpacing(8)
        self.speed_label = QLabel("↓ 0 B/s   ↑ 0 B/s")
        self.amount_label = QLabel("已下载：0 B / 未知")
        self.peers_label = QLabel("连接节点：0   种子节点：0")
        self.network_label = QLabel(f"监听端口：{self.engine.listen_port}（自动尝试端口映射）")
        stats.addWidget(self.speed_label, 0, 0)
        stats.addWidget(self.amount_label, 0, 1)
        stats.addWidget(self.peers_label, 1, 0)
        stats.addWidget(self.network_label, 1, 1)
        layout.addLayout(stats)

        self.message_label = QLabel("")
        self.message_label.setWordWrap(True)
        layout.addWidget(self.message_label)
        layout.addStretch(1)

    def _restore_window_state(self) -> None:
        saved_path = self.settings.value("last_save_path", "")
        if saved_path:
            self.folder_edit.setText(str(saved_path))

    def _restore_last_task(self) -> None:
        if not self.engine.restore_last_task():
            return
        self.magnet_edit.setText(self.engine.current_magnet)
        self.folder_edit.setText(self.engine.current_path)
        self._set_inputs_enabled(False)
        self.message_label.setText("已恢复上次未完成任务，点击“开始下载”继续。")

    def _set_inputs_enabled(self, enabled: bool) -> None:
        self.magnet_edit.setEnabled(enabled)
        self.folder_edit.setEnabled(enabled)
        self.choose_folder_button.setEnabled(enabled)

    def choose_folder(self) -> None:
        initial = self.folder_edit.text() or str(Path.home() / "Downloads")
        folder = QFileDialog.getExistingDirectory(self, "选择下载文件夹", initial)
        if folder:
            self.folder_edit.setText(folder)
            self.settings.setValue("last_save_path", folder)

    def start_or_resume(self) -> None:
        try:
            if self.engine.has_task():
                snapshot = self.engine.snapshot()
                if snapshot and snapshot.completed:
                    QMessageBox.information(self, APP_NAME, "当前任务已经完成。请点击“新建任务”。")
                    return
                self.engine.resume()
            else:
                magnet = self.magnet_edit.text().strip()
                folder = self.folder_edit.text().strip()
                self.engine.start_new(magnet, folder)
                self._set_inputs_enabled(False)
            self.message_label.setText("正在发现节点并建立连接…")
        except (ValueError, OSError, RuntimeError) as exc:
            QMessageBox.warning(self, APP_NAME, str(exc))

    def pause_download(self) -> None:
        self.engine.pause()
        if self.engine.has_task():
            self.message_label.setText("下载已暂停。点击“开始下载”即可继续。")

    def new_task(self) -> None:
        if self.engine.has_task():
            snapshot = self.engine.snapshot()
            if snapshot and not snapshot.paused and not snapshot.completed:
                answer = QMessageBox.question(
                    self,
                    APP_NAME,
                    "当前下载会被停止，但已下载文件不会删除。要新建任务吗？",
                    QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
                    QMessageBox.StandardButton.No,
                )
                if answer != QMessageBox.StandardButton.Yes:
                    return
            self.engine.remove_task()

        self.magnet_edit.clear()
        self._set_inputs_enabled(True)
        self.file_name_label.setText("尚未开始下载")
        self.state_label.setText("状态：准备就绪")
        self.progress.setValue(0)
        self.progress_label.setText("0.0%")
        self.speed_label.setText("↓ 0 B/s   ↑ 0 B/s")
        self.amount_label.setText("已下载：0 B / 未知")
        self.peers_label.setText("连接节点：0   种子节点：0")
        self.message_label.setText("")

    def open_folder(self) -> None:
        folder = self.engine.current_path or self.folder_edit.text()
        if not folder:
            return
        path = Path(folder)
        if path.exists():
            QDesktopServices.openUrl(QUrl.fromLocalFile(str(path)))

    def refresh_status(self) -> None:
        snapshot = self.engine.snapshot()
        if snapshot is None:
            self.start_button.setEnabled(True)
            self.pause_button.setEnabled(False)
            self.new_task_button.setEnabled(False)
            self.open_folder_button.setEnabled(bool(self.folder_edit.text()))
            return

        self.new_task_button.setEnabled(True)
        self.open_folder_button.setEnabled(bool(self.engine.current_path))
        self.file_name_label.setText(snapshot.name)
        self.state_label.setText(f"状态：{snapshot.state}")
        self.progress.setValue(round(snapshot.progress * 10))
        self.progress_label.setText(f"{snapshot.progress:.1f}%")
        self.speed_label.setText(
            f"↓ {format_speed(snapshot.download_rate)}   ↑ {format_speed(snapshot.upload_rate)}"
        )
        total = format_bytes(snapshot.total) if snapshot.total > 0 else "未知"
        self.amount_label.setText(f"已下载：{format_bytes(snapshot.downloaded)} / {total}")
        self.peers_label.setText(f"连接节点：{snapshot.peers}   种子节点：{snapshot.seeds}")

        if snapshot.completed:
            self.start_button.setEnabled(False)
            self.pause_button.setEnabled(False)
            self.message_label.setText("下载完成。已自动暂停上传。")
        elif snapshot.paused:
            self.start_button.setEnabled(True)
            self.start_button.setText("继续下载")
            self.pause_button.setEnabled(False)
            if not snapshot.error:
                self.message_label.setText("下载已暂停。")
        else:
            self.start_button.setEnabled(False)
            self.start_button.setText("下载中")
            self.pause_button.setEnabled(True)
            if not snapshot.error:
                self.message_label.setText("正在下载。磁力链接刚开始时需要先获取元数据。")

        if snapshot.error:
            self.message_label.setText(f"提示：{snapshot.error}")

    def closeEvent(self, event) -> None:  # type: ignore[override]
        self.settings.setValue("last_save_path", self.folder_edit.text())
        self.engine.shutdown()
        event.accept()


def app_data_dir() -> Path:
    location = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.AppDataLocation)
    return Path(location or str(Path.home() / f".{APP_NAME.lower()}"))


def main() -> int:
    app = QApplication(sys.argv)
    app.setOrganizationName(APP_NAME)
    app.setApplicationName(APP_NAME)

    if LIBTORRENT_IMPORT_ERROR is not None:
        QMessageBox.critical(
            None,
            APP_NAME,
            "缺少 libtorrent 组件。\n\n"
            "请在项目文件夹运行：\n"
            "pip install -r requirements.txt\n\n"
            f"详细错误：{LIBTORRENT_IMPORT_ERROR}",
        )
        return 1

    try:
        engine = DownloadEngine(app_data_dir())
    except Exception as exc:
        QMessageBox.critical(None, APP_NAME, f"下载引擎初始化失败：\n{exc}")
        return 1

    window = MainWindow(engine)
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
