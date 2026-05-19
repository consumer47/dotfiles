from typing import List, Tuple
from PIL import Image, ImageDraw, ImageFont
import math
from models import PrintJob


def calculate_job_char_count(job: PrintJob) -> int:
    """Calculate total character count for a job (all lines combined)"""
    return sum(len(line) for line in job.lines)


def distribute_jobs_across_lines(jobs: List[PrintJob], num_lines: int) -> List[List[PrintJob]]:
    """
    Distribute jobs across N lines to balance character counts.
    Each job stays intact (atomic unit).
    Returns list of lines, where each line is a list of jobs.
    """
    if not jobs:
        return [[] for _ in range(num_lines)]
    
    if num_lines == 1:
        return [jobs]
    
    # Calculate character count for each job
    job_chars = [(job, calculate_job_char_count(job)) for job in jobs]
    
    # Sort by character count (descending) for better distribution
    job_chars.sort(key=lambda x: x[1], reverse=True)
    
    # Initialize lines with empty lists and character counts
    lines = [[] for _ in range(num_lines)]
    line_chars = [0] * num_lines
    
    # Distribute jobs using greedy algorithm
    for job, char_count in job_chars:
        # Find line with least characters
        min_line_idx = min(range(num_lines), key=lambda i: line_chars[i])
        lines[min_line_idx].append(job)
        line_chars[min_line_idx] += char_count
    
    return lines


def generate_prepreview_png(
    jobs: List[PrintJob],
    line_count: int,
    width: int = 800,
    height: int = 200,
    padding: int = 10
) -> Image.Image:
    """
    Generate a PNG preview showing how jobs are distributed across lines.
    
    Args:
        jobs: List of jobs to distribute
        line_count: Number of lines to distribute across (1-4)
        width: Image width in pixels
        height: Image height in pixels
        padding: Padding between elements
    
    Returns:
        PIL Image object
    """
    if not jobs:
        # Return empty image
        img = Image.new('RGB', (width, height), color='white')
        draw = ImageDraw.Draw(img)
        draw.text((10, 10), "No jobs in queue", fill='black')
        return img
    
    # Distribute jobs across lines
    distributed_lines = distribute_jobs_across_lines(jobs, line_count)
    
    # Create image
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    # Try to load a font, fallback to default if not available
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
    except:
        font = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    y_pos = padding
    line_height = (height - padding * 2) // line_count
    
    for line_idx, line_jobs in enumerate(distributed_lines):
        if not line_jobs:
            continue
        
        # Draw line number
        draw.text((padding, y_pos), f"Line {line_idx + 1}:", fill='gray', font=font_small)
        
        x_pos = padding + 80  # Start after "Line X:"
        current_y = y_pos
        
        for job_idx, job in enumerate(line_jobs):
            # Draw job separator (except for first job)
            if job_idx > 0:
                draw.rectangle([x_pos, current_y, x_pos + 2, current_y + line_height - 5], fill='lightgray')
                x_pos += 5
            
            # Draw job text (all lines of the job)
            job_text = " | ".join(job.lines)  # Join job lines with separator
            draw.text((x_pos, current_y), job_text, fill='black', font=font)
            
            # Estimate width (rough calculation)
            text_width = len(job_text) * 8  # Approximate character width
            x_pos += text_width + padding
        
        y_pos += line_height
    
    # Draw summary
    total_chars = sum(calculate_job_char_count(job) for job in jobs)
    chars_per_line = total_chars / line_count if line_count > 0 else 0
    summary = f"Total: {len(jobs)} jobs, {total_chars} chars, ~{int(chars_per_line)} chars/line"
    draw.text((padding, height - 20), summary, fill='darkgray', font=font_small)
    
    return img


def get_distribution_stats(jobs: List[PrintJob], line_count: int) -> dict:
    """Get statistics about job distribution"""
    if not jobs:
        return {
            "total_jobs": 0,
            "total_chars": 0,
            "chars_per_line": 0,
            "distribution": []
        }
    
    distributed_lines = distribute_jobs_across_lines(jobs, line_count)
    
    stats = {
        "total_jobs": len(jobs),
        "total_chars": sum(calculate_job_char_count(job) for job in jobs),
        "chars_per_line": [],
        "distribution": []
    }
    
    for line_idx, line_jobs in enumerate(distributed_lines):
        line_chars = sum(calculate_job_char_count(job) for job in line_jobs)
        stats["chars_per_line"].append(line_chars)
        stats["distribution"].append({
            "line": line_idx + 1,
            "jobs": [{"id": job.id, "text": " | ".join(job.lines)} for job in line_jobs],
            "char_count": line_chars
        })
    
    return stats

