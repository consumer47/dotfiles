from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from typing import List
import uuid
from datetime import datetime
import json
from pathlib import Path

from models import (
    PrintJob, PrintJobCreate, Template, TemplateCreate,
    QRCodeRequest, PreviewRequest, PrepreviewRequest, JobQueueResponse,
    MessageResponse, PrintHistory, FontSize
)
from printer import PrinterInterface
from templates import TemplateManager
from prepreview import generate_prepreview_png, get_distribution_stats

app = FastAPI(title="Brother Label Printer API", version="1.0.0")

# Initialize components
printer = PrinterInterface("/app/brother-label-print.sh")
template_manager = TemplateManager("/app/data/templates.json")
history_path = Path("/app/data/history.json")

# In-memory job queue
job_queue: List[PrintJob] = []

# Load history
def load_history() -> List[PrintHistory]:
    if history_path.exists():
        try:
            with open(history_path, 'r') as f:
                data = json.load(f)
                return [
                    PrintHistory(**{
                        **h,
                        "printed_at": datetime.fromisoformat(h["printed_at"]),
                        "jobs": [PrintJob(**{**j, "created_at": datetime.fromisoformat(j["created_at"]) if j.get("created_at") else None}) for j in h["jobs"]]
                    })
                    for h in data
                ]
        except Exception:
            return []
    return []

def save_history(history: List[PrintHistory]):
    history_path.parent.mkdir(parents=True, exist_ok=True)
    data = [
        {
            **h.dict(),
            "printed_at": h.printed_at.isoformat(),
            "jobs": [
                {
                    **j.dict(),
                    "created_at": j.created_at.isoformat() if j.created_at else None
                }
                for j in h.jobs
            ]
        }
        for h in history
    ]
    with open(history_path, 'w') as f:
        json.dump(data, f, indent=2)


# API Routes

@app.get("/api/jobs", response_model=JobQueueResponse)
async def get_jobs():
    """Get all jobs in the queue"""
    return JobQueueResponse(jobs=job_queue, total=len(job_queue))


@app.post("/api/jobs", response_model=PrintJob)
async def create_job(job_data: PrintJobCreate):
    """Create a new print job and add it to the queue"""
    job = PrintJob(
        id=str(uuid.uuid4()),
        lines=job_data.lines,
        font_size=job_data.font_size,
        created_at=datetime.now()
    )
    job_queue.append(job)
    return job


@app.delete("/api/jobs/{job_id}", response_model=MessageResponse)
async def delete_job(job_id: str):
    """Remove a job from the queue"""
    global job_queue
    original_len = len(job_queue)
    job_queue = [j for j in job_queue if j.id != job_id]
    if len(job_queue) == original_len:
        raise HTTPException(status_code=404, detail="Job not found")
    return MessageResponse(message="Job removed from queue")


@app.post("/api/jobs/print", response_model=MessageResponse)
async def print_all_jobs(request: PrepreviewRequest = PrepreviewRequest(line_count=1)):
    """
    Print all jobs in the queue, distributed across N lines.
    Defaults to 1 line if not specified.
    """
    if not job_queue:
        raise HTTPException(status_code=400, detail="No jobs in queue")
    
    jobs_to_print = job_queue.copy()
    success, error = printer.print_jobs(jobs_to_print, line_count=request.line_count)
    
    # Save to history
    history = load_history()
    history_entry = PrintHistory(
        id=str(uuid.uuid4()),
        jobs=jobs_to_print,
        printed_at=datetime.now(),
        success=success,
        error=error
    )
    history.append(history_entry)
    save_history(history)
    
    # Clear queue if successful
    if success:
        job_queue.clear()
        return MessageResponse(message=f"Successfully printed {len(jobs_to_print)} job(s)")
    else:
        raise HTTPException(status_code=500, detail=f"Print failed: {error}")


@app.post("/api/jobs/preview")
async def generate_preview(request: PreviewRequest):
    """Generate a preview PNG of a label"""
    try:
        preview_path = printer.generate_preview(
            request.lines, 
            request.font_size,
            force_tape_width=request.force_tape_width
        )
        if not Path(preview_path).exists():
            raise HTTPException(status_code=500, detail="Preview file was not created")
        return FileResponse(preview_path, media_type="image/png")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/jobs/preview-queue")
async def generate_queue_preview(request: PrepreviewRequest = PrepreviewRequest(line_count=1)):
    """
    Generate a preview PNG of all jobs in the queue distributed across lines.
    Uses the same distribution logic as print_jobs.
    Uses --force-tape-width to allow preview generation without printer connected.
    """
    if not job_queue:
        raise HTTPException(status_code=400, detail="No jobs in queue")
    
    try:
        # Use force_tape_width=128 (typical tape width) to allow preview without printer
        preview_path = printer.generate_queue_preview(job_queue, line_count=request.line_count, force_tape_width=128)
        if not Path(preview_path).exists():
            raise HTTPException(status_code=500, detail="Preview file was not created")
        return FileResponse(preview_path, media_type="image/png")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/printer/info")
async def get_printer_info():
    """Get printer information"""
    try:
        info = printer.get_printer_info()
        return {"info": info}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/templates", response_model=List[Template])
async def list_templates():
    """List all saved templates"""
    return template_manager.list_templates()


@app.post("/api/templates", response_model=Template)
async def create_template(template_data: TemplateCreate):
    """Create a new template"""
    return template_manager.create_template(template_data)


@app.get("/api/templates/{template_id}", response_model=Template)
async def get_template(template_id: str):
    """Get a template by ID"""
    template = template_manager.get_template(template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return template


@app.delete("/api/templates/{template_id}", response_model=MessageResponse)
async def delete_template(template_id: str):
    """Delete a template"""
    if not template_manager.delete_template(template_id):
        raise HTTPException(status_code=404, detail="Template not found")
    return MessageResponse(message="Template deleted")


@app.get("/api/history", response_model=List[PrintHistory])
async def get_history():
    """Get print history"""
    return load_history()


@app.post("/api/jobs/prepreview")
async def generate_prepreview(request: PrepreviewRequest):
    """Generate a prepreview showing how jobs are distributed across lines"""
    if not job_queue:
        raise HTTPException(status_code=400, detail="No jobs in queue")
    
    try:
        # Generate PNG preview
        preview_img = generate_prepreview_png(job_queue, request.line_count)
        
        # Save to temporary file
        import tempfile
        import os
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
        preview_img.save(temp_file.name, 'PNG')
        temp_file.close()
        
        return FileResponse(temp_file.name, media_type="image/png", filename="prepreview.png")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/jobs/prepreview/stats")
async def get_prepreview_stats(line_count: int = 2):
    """Get statistics about job distribution for given line count"""
    if line_count < 1 or line_count > 4:
        raise HTTPException(status_code=400, detail="line_count must be between 1 and 4")
    
    if not job_queue:
        return get_distribution_stats([], line_count)
    
    return get_distribution_stats(job_queue, line_count)


@app.post("/api/qrcode", response_model=MessageResponse)
async def print_qrcode(request: QRCodeRequest):
    """Generate and print a QR code"""
    success, error = printer.print_qrcode(request.data, request.label_text, request.font_size)
    
    if success:
        # Save to history
        history = load_history()
        qr_job = PrintJob(
            id=str(uuid.uuid4()),
            lines=[f"QR: {request.data[:30]}..."] if len(request.data) > 30 else [f"QR: {request.data}"],
            font_size=request.font_size,
            created_at=datetime.now()
        )
        history_entry = PrintHistory(
            id=str(uuid.uuid4()),
            jobs=[qr_job],
            printed_at=datetime.now(),
            success=True
        )
        history.append(history_entry)
        save_history(history)
        
        return MessageResponse(message="QR code printed successfully")
    else:
        raise HTTPException(status_code=500, detail=f"QR code print failed: {error}")


# Mount static files for web UI
app.mount("/", StaticFiles(directory="/app/static", html=True), name="static")

