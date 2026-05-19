import subprocess
import os
import json
from typing import List, Optional
from pathlib import Path
from models import PrintJob, FontSize
from prepreview import distribute_jobs_across_lines


class PrinterInterface:
    def __init__(self, script_path: str = "/app/brother-label-print.sh", docker_compose_dir: str = "/app/docker"):
        self.script_path = script_path
        # Docker compose directory (where docker-compose.yml is located)
        self.docker_compose_dir = Path(docker_compose_dir)
        # Workspace is mounted at docker/workspace, which maps to /workspace in ptouch-print container
        # But from server container perspective, it's at /app/workspace (mounted volume)
        self.workspace = Path("/app/workspace")
        self.workspace.mkdir(exist_ok=True)
        
        # Ensure script is executable (skip if read-only mount)
        script_file = Path(script_path)
        if script_file.exists():
            try:
                os.chmod(script_file, 0o755)
            except OSError:
                # File might be read-only mounted, that's okay
                pass
    
    def _get_font_size_arg(self, font_size: FontSize) -> List[str]:
        """Convert FontSize enum to ptouch-print font size argument"""
        if font_size == FontSize.AUTO:
            return []
        elif font_size == FontSize.SMALL:
            return ["--fontsize", "32"]
        elif font_size == FontSize.MEDIUM:
            return ["--fontsize", "48"]
        elif font_size == FontSize.LARGE:
            return ["--fontsize", "94"]
        return []
    
    def _run_docker_command(self, args: List[str], cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
        """
        Runs a docker compose command for the ptouch-print service.
        Runs from the docker-compose directory, but ptouch-print writes files relative to /workspace.
        """
        if cwd is None:
            cwd = self.docker_compose_dir
        
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=60,
            cwd=str(cwd)
        )
        return result
    
    def generate_preview(self, lines: List[str], font_size: FontSize = FontSize.AUTO, force_tape_width: Optional[int] = None) -> str:
        """Generate a PNG preview of the label"""
        preview_filename = f"preview_{os.urandom(4).hex()}.png"
        preview_path = self.workspace / preview_filename
        
        # Build command with --text for first line, -n for subsequent lines
        # Use --workdir to ensure ptouch-print runs from /workspace directory
        cmd = ["docker", "compose", "run", "--rm", "-w", "/workspace", "ptouch-print"]
        
        # Add --force-tape-width if specified (allows preview without printer)
        if force_tape_width:
            cmd.extend(["--force-tape-width", str(force_tape_width)])
        
        if lines:
            cmd.extend(["--text", lines[0]])
            for line in lines[1:]:
                cmd.extend(["-n", line])
        
        cmd.extend(self._get_font_size_arg(font_size))
        # Use relative path (ptouch-print writes to current working directory)
        # We'll run the command from the workspace directory
        cmd.extend(["--writepng", preview_filename])
        
        try:
            result = self._run_docker_command(cmd)
            
            # Wait a moment for file to be written (especially with --force-tape-width)
            import time
            time.sleep(1.5)  # Increased wait time
            
            # The file is created in /workspace inside ptouch-print container
            # This maps to docker/workspace on host, which is mounted to /app/workspace in server container
            # So check /app/workspace directly first (which is self.workspace / preview_filename = preview_path)
            if preview_path.exists():
                return str(preview_path)
            
            # Also check docker workspace path as fallback (for debugging)
            docker_workspace_path = self.docker_compose_dir / "workspace" / preview_filename
            if docker_workspace_path.exists():
                import shutil
                shutil.copy2(docker_workspace_path, preview_path)
                return str(preview_path)
            
            # Debug: list files in workspace to see what's there
            import logging
            logging.basicConfig(level=logging.INFO)
            logger = logging.getLogger(__name__)
            if self.workspace.exists():
                workspace_files = list(self.workspace.glob("*.png"))
                logger.warning(f"Workspace files: {[str(f.name) for f in workspace_files]}")
                logger.warning(f"Looking for: {preview_filename}")
            
            # With --force-tape-width, ptouch-print should work without printer
            # Check if it's a different error
            if result.returncode != 0:
                error_text = (result.stderr or "") + (result.stdout or "")
                if "No P-Touch printer found" in error_text and not force_tape_width:
                    raise Exception("Preview requires printer to be on. Please turn on the printer (it may have auto-off enabled) or use force_tape_width.")
                raise Exception(f"Preview generation failed: {result.stderr}")
            raise Exception(f"Preview file was not created. stdout: {result.stdout}, stderr: {result.stderr}")
        except subprocess.TimeoutExpired:
            raise Exception("Preview generation timed out")
    
    def generate_queue_preview(self, jobs: List[PrintJob], line_count: int = 1, force_tape_width: Optional[int] = None) -> str:
        """
        Generate a PNG preview of all jobs distributed across lines (like they will be printed).
        Uses the same distribution logic as print_jobs.
        """
        preview_filename = f"queue_preview_{os.urandom(4).hex()}.png"
        preview_path = self.workspace / preview_filename
        
        # Distribute jobs across lines (same as print_jobs)
        distributed_lines = distribute_jobs_across_lines(jobs, line_count)
        
        # Debug: log distribution
        import logging
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)
        logger.warning(f"Number of distributed lines: {len(distributed_lines)}")
        for idx, line_jobs in enumerate(distributed_lines):
            logger.warning(f"Line {idx} has {len(line_jobs)} jobs: {[j.lines for j in line_jobs]}")
        
        # Build command - use docker compose directly
        # Use --workdir to ensure ptouch-print runs from /workspace directory
        cmd = ["docker", "compose", "run", "--rm", "-w", "/workspace", "ptouch-print"]
        
        # Add --force-tape-width if specified (allows preview without printer)
        if force_tape_width:
            cmd.extend(["--force-tape-width", str(force_tape_width)])
        
        for line_idx, line_jobs in enumerate(distributed_lines):
            if not line_jobs:
                continue
            
            # Concatenate all jobs on this line
            line_texts = []
            for job in line_jobs:
                job_text = " ".join(job.lines)
                line_texts.append(job_text)
            
            combined_line = " | ".join(line_texts)
            
            # First line uses --text, subsequent lines use -n/--newline
            if line_idx == 0:
                cmd.extend(["--text", combined_line])
            else:
                cmd.extend(["-n", combined_line])
        
        # Use font size from first job
        if jobs and jobs[0].font_size != FontSize.AUTO:
            cmd.extend(self._get_font_size_arg(jobs[0].font_size))
        
        # Add writepng - use relative path (ptouch-print writes to current working directory)
        # We'll run the command from the workspace directory
        cmd.extend(["--writepng", preview_filename])
        
        try:
            result = self._run_docker_command(cmd)
            
            # Wait a moment for file to be written (file might be written asynchronously)
            import time
            time.sleep(2.0)  # Increased wait time - ptouch-print may take time to write file
            
            # The file is created in /workspace inside ptouch-print container
            # This maps to docker/workspace on host, which is mounted to /app/workspace in server container
            # So check /app/workspace directly first (which is self.workspace / preview_filename = preview_path)
            if preview_path.exists():
                return str(preview_path)
            
            # Also check docker workspace path as fallback (for debugging)
            docker_workspace_path = self.docker_compose_dir / "workspace" / preview_filename
            if docker_workspace_path.exists():
                import shutil
                shutil.copy2(docker_workspace_path, preview_path)
                return str(preview_path)
            
            # Debug: list files in workspace to see what's there
            import logging
            logging.basicConfig(level=logging.INFO)
            logger = logging.getLogger(__name__)
            logger.warning(f"Command executed: {' '.join(repr(arg) for arg in cmd)}")
            logger.warning(f"Return code: {result.returncode}")
            if self.workspace.exists():
                workspace_files = sorted(self.workspace.glob("*.png"), key=lambda p: p.stat().st_mtime, reverse=True)
                logger.warning(f"Workspace files (newest first): {[str(f.name) for f in workspace_files[:5]]}")
                logger.warning(f"Looking for: {preview_filename}")
                logger.warning(f"Preview path exists: {preview_path.exists()}")
                logger.warning(f"Docker workspace path exists: {docker_workspace_path.exists()}")
                # Check if file was just created (might be a timing issue)
                if workspace_files:
                    newest_file = workspace_files[0]
                    logger.warning(f"Newest file: {newest_file.name}, modified: {newest_file.stat().st_mtime}")
            
            # Check for errors
            if result.returncode != 0:
                error_text = (result.stderr or "") + (result.stdout or "")
                if "No P-Touch printer found" in error_text and not force_tape_width:
                    raise Exception("Queue preview requires printer to be on. Please turn on the printer (it may have auto-off enabled) or use force_tape_width.")
                raise Exception(f"Queue preview generation failed: {result.stderr}")
            raise Exception(f"Preview file was not created. stdout: {result.stdout}, stderr: {result.stderr}")
        except subprocess.TimeoutExpired:
            raise Exception("Queue preview generation timed out")
    
    def print_jobs(self, jobs: List[PrintJob], line_count: int = 1) -> tuple[bool, Optional[str]]:
        """
        Print multiple jobs distributed across N lines.
        Jobs are distributed to balance character counts and minimize width waste.
        Each distributed line becomes one --text argument to the CLI tool.
        
        Args:
            jobs: List of jobs to print
            line_count: Number of lines to distribute jobs across (1-4)
        """
        if not jobs:
            return False, "No jobs to print"
        
        if line_count < 1 or line_count > 4:
            return False, f"line_count must be between 1 and 4, got {line_count}"
        
        # Distribute jobs across lines
        distributed_lines = distribute_jobs_across_lines(jobs, line_count)
        
        # Build command - use docker compose directly
        # ptouch-print uses --text for first line, -n/--newline for subsequent lines
        # Example: --text "line1" -n "line2" -n "line3"
        # Use --workdir to ensure ptouch-print runs from /workspace directory
        cmd = ["docker", "compose", "run", "--rm", "-w", "/workspace", "ptouch-print"]
        
        for line_idx, line_jobs in enumerate(distributed_lines):
            if not line_jobs:
                continue
            
            # Concatenate all jobs on this line
            # Each job's lines are joined with spaces, jobs are separated by " | "
            line_texts = []
            for job in line_jobs:
                # Join job's lines with spaces
                job_text = " ".join(job.lines)
                line_texts.append(job_text)
            
            # Join all jobs on this line with " | " separator
            combined_line = " | ".join(line_texts)
            
            # First line uses --text, subsequent lines use -n/--newline
            if line_idx == 0:
                cmd.extend(["--text", combined_line])
            else:
                cmd.extend(["-n", combined_line])
        
        # Use font size from first job (or could average, but simpler to use first)
        if jobs and jobs[0].font_size != FontSize.AUTO:
            cmd.extend(self._get_font_size_arg(jobs[0].font_size))
        
        # Debug: log the exact command
        import logging
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)
        logger.info(f"Print command: {' '.join(repr(arg) for arg in cmd)}")
        logger.info(f"Distributed lines: {[[j.lines for j in line_jobs] for line_jobs in distributed_lines]}")
        
        try:
            result = self._run_docker_command(cmd)
            if result.returncode != 0:
                return False, result.stderr
            return True, None
        except subprocess.TimeoutExpired:
            return False, "Print job timed out"
        except Exception as e:
            return False, str(e)
    
    def get_printer_info(self) -> str:
        """Get printer information using --info flag"""
        cmd = ["docker", "compose", "run", "--rm", "ptouch-print", "--info"]
        
        try:
            result = self._run_docker_command(cmd)
            if result.returncode != 0:
                raise Exception(f"Failed to get printer info: {result.stderr}")
            return result.stdout
        except Exception as e:
            raise Exception(f"Error getting printer info: {str(e)}")
    
    def print_qrcode(self, data: str, label_text: Optional[str] = None, font_size: FontSize = FontSize.AUTO) -> tuple[bool, Optional[str]]:
        """Print a QR code with optional label text"""
        # For now, we'll generate QR code as PNG and print it
        # This will be enhanced when QR code generation is added
        try:
            # Import qrcode here to avoid dependency if not needed
            import qrcode
            from PIL import Image
            
            # Generate QR code
            qr = qrcode.QRCode(version=1, box_size=10, border=4)
            qr.add_data(data)
            qr.make(fit=True)
            qr_img = qr.make_image(fill_color="black", back_color="white")
            
            # Convert to monochrome PNG
            qr_path = self.workspace / f"qrcode_{os.urandom(4).hex()}.png"
            qr_img = qr_img.convert("1")  # Convert to 1-bit (monochrome)
            qr_img.save(qr_path)
            
            cmd = ["bash", str(self.script_path)]
            
            # Add label text if provided
            if label_text:
                for line in label_text.split("\n")[:4]:
                    if line.strip():
                        cmd.extend(["--text", line.strip()])
                cmd.extend(self._get_font_size_arg(font_size))
                cmd.extend(["--pad", "10"])
            
            # Add QR code image
            cmd.extend(["--image", str(qr_path)])
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,
                cwd=str(self.docker_compose_dir)
            )
            
            # Clean up temp file
            if qr_path.exists():
                qr_path.unlink()
            
            if result.returncode != 0:
                return False, result.stderr
            return True, None
        except ImportError:
            return False, "QR code library not available"
        except Exception as e:
            return False, str(e)

