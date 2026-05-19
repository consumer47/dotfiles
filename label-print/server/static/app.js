const API_BASE = '/api';

let currentLines = 1;
let currentJobData = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadQueue();
    loadTemplates();
    loadHistory();
    
    // Job form
    document.getElementById('job-form').addEventListener('submit', handleJobSubmit);
    document.getElementById('add-line-btn').addEventListener('click', addLine);
    document.getElementById('remove-line-btn').addEventListener('click', removeLine);
    document.getElementById('preview-btn').addEventListener('click', generatePreview);
    
    // Queue actions
    document.getElementById('preview-queue-btn').addEventListener('click', previewQueue);
    document.getElementById('print-all-btn').addEventListener('click', printAll);
    document.getElementById('clear-queue-btn').addEventListener('click', clearQueue);
    document.getElementById('printer-info-btn').addEventListener('click', getPrinterInfo);
    
    // Templates
    document.getElementById('save-template-btn').addEventListener('click', saveTemplate);
    
    // QR Code
    document.getElementById('qrcode-form').addEventListener('submit', handleQRCodeSubmit);
    
    // Prepreview
    document.getElementById('generate-prepreview-btn').addEventListener('click', generatePrepreview);
});

// Job Queue Functions
async function loadQueue() {
    try {
        const response = await fetch(`${API_BASE}/jobs`);
        const data = await response.json();
        renderQueue(data.jobs);
    } catch (error) {
        console.error('Failed to load queue:', error);
    }
}

function renderQueue(jobs) {
    const list = document.getElementById('job-list');
    const empty = document.getElementById('queue-empty');
    const count = document.getElementById('queue-count');
    const printBtn = document.getElementById('print-all-btn');
    const clearBtn = document.getElementById('clear-queue-btn');
    
    const previewQueueBtn = document.getElementById('preview-queue-btn');
    count.textContent = jobs.length;
    printBtn.disabled = jobs.length === 0;
    clearBtn.disabled = jobs.length === 0;
    previewQueueBtn.disabled = jobs.length === 0;
    
    if (jobs.length === 0) {
        empty.style.display = 'block';
        list.innerHTML = '';
        return;
    }
    
    empty.style.display = 'none';
    list.innerHTML = jobs.map(job => `
        <li class="job-item">
            <div class="job-item-header">
                <div class="job-lines">
                    ${job.lines.map(line => `<div>${escapeHtml(line)}</div>`).join('')}
                </div>
                <button class="delete-btn" onclick="deleteJob('${job.id}')">Delete</button>
            </div>
        </li>
    `).join('');
}

async function handleJobSubmit(e) {
    e.preventDefault();
    const lines = Array.from(document.querySelectorAll('.line-input'))
        .map(input => input.value.trim())
        .filter(line => line.length > 0);
    
    if (lines.length === 0) {
        alert('Please enter at least one line');
        return;
    }
    
    const fontSize = document.getElementById('font-size').value;
    
    try {
        const response = await fetch(`${API_BASE}/jobs`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                lines: lines,
                font_size: fontSize
            })
        });
        
        if (response.ok) {
            const job = await response.json();
            loadQueue();
            document.getElementById('job-form').reset();
            currentLines = 1;
            updateLineInputs();
            alert('Job added to queue!');
        } else {
            const error = await response.json();
            alert(`Failed to add job: ${error.detail}`);
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

async function deleteJob(jobId) {
    try {
        const response = await fetch(`${API_BASE}/jobs/${jobId}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            loadQueue();
        } else {
            alert('Failed to delete job');
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

async function printAll() {
    if (!confirm(`Print ${document.getElementById('queue-count').textContent} job(s)?`)) {
        return;
    }
    
    const lineCount = parseInt(document.getElementById('print-line-count').value);
    
    try {
        const response = await fetch(`${API_BASE}/jobs/print`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                line_count: lineCount
            })
        });
        
        if (response.ok) {
            const result = await response.json();
            alert(result.message);
            loadQueue();
            loadHistory();
        } else {
            const error = await response.json();
            alert(`Print failed: ${error.detail}`);
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

async function clearQueue() {
    if (!confirm('Clear all jobs from queue?')) {
        return;
    }
    
    // Delete all jobs
    try {
        const response = await fetch(`${API_BASE}/jobs`);
        const data = await response.json();
        
        await Promise.all(data.jobs.map(job => 
            fetch(`${API_BASE}/jobs/${job.id}`, { method: 'DELETE' })
        ));
        
        loadQueue();
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

// Preview Functions
async function generatePreview() {
    const lines = Array.from(document.querySelectorAll('.line-input'))
        .map(input => input.value.trim())
        .filter(line => line.length > 0);
    
    if (lines.length === 0) {
        alert('Please enter at least one line');
        return;
    }
    
    const fontSize = document.getElementById('font-size').value;
    
    try {
        const response = await fetch(`${API_BASE}/jobs/preview`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                lines: lines,
                font_size: fontSize
            })
        });
        
        if (response.ok) {
            const blob = await response.blob();
            const url = URL.createObjectURL(blob);
            const previewSection = document.getElementById('preview-section');
            const previewContainer = document.getElementById('preview-container');
            previewContainer.innerHTML = `<h3>Single Label Preview</h3><img src="${url}" alt="Preview">`;
            previewSection.style.display = 'block';
            previewSection.scrollIntoView({ behavior: 'smooth' });
        } else {
            const error = await response.json();
            alert(`Preview failed: ${error.detail}`);
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

async function previewQueue() {
    try {
        const response = await fetch(`${API_BASE}/jobs/preview-queue`, {
            method: 'POST'
        });
        
        if (response.ok) {
            const blob = await response.blob();
            const url = URL.createObjectURL(blob);
            const previewSection = document.getElementById('preview-section');
            const previewContainer = document.getElementById('preview-container');
            previewContainer.innerHTML = `<h3>Queue Preview (All jobs concatenated)</h3><img src="${url}" alt="Queue Preview">`;
            previewSection.style.display = 'block';
            previewSection.scrollIntoView({ behavior: 'smooth' });
        } else {
            const error = await response.json();
            alert(`Queue preview failed: ${error.detail}`);
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

// Line Management
function addLine() {
    if (currentLines >= 4) return;
    currentLines++;
    updateLineInputs();
}

function removeLine() {
    if (currentLines <= 1) return;
    currentLines--;
    updateLineInputs();
}

function updateLineInputs() {
    const container = document.getElementById('lines-container');
    container.innerHTML = '';
    
    for (let i = 0; i < currentLines; i++) {
        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'line-input';
        input.placeholder = `Line ${i + 1}`;
        container.appendChild(input);
    }
    
    document.getElementById('add-line-btn').style.display = currentLines >= 4 ? 'none' : 'inline-block';
    document.getElementById('remove-line-btn').style.display = currentLines > 1 ? 'inline-block' : 'none';
}

// Template Functions
async function loadTemplates() {
    try {
        const response = await fetch(`${API_BASE}/templates`);
        const templates = await response.json();
        renderTemplates(templates);
    } catch (error) {
        console.error('Failed to load templates:', error);
    }
}

function renderTemplates(templates) {
    const list = document.getElementById('template-list');
    const empty = document.getElementById('templates-empty');
    
    if (templates.length === 0) {
        empty.style.display = 'block';
        list.innerHTML = '';
        return;
    }
    
    empty.style.display = 'none';
    list.innerHTML = templates.map(template => `
        <li class="template-item" onclick="loadTemplate('${template.id}')">
            <div class="template-name">${escapeHtml(template.name)}</div>
            <div class="job-lines">
                ${template.lines.map(line => `<div>${escapeHtml(line)}</div>`).join('')}
            </div>
        </li>
    `).join('');
}

async function loadTemplate(templateId) {
    try {
        const response = await fetch(`${API_BASE}/templates/${templateId}`);
        const template = await response.json();
        
        // Fill form with template data
        currentLines = template.lines.length;
        updateLineInputs();
        
        const inputs = document.querySelectorAll('.line-input');
        template.lines.forEach((line, i) => {
            if (inputs[i]) inputs[i].value = line;
        });
        
        document.getElementById('font-size').value = template.font_size;
    } catch (error) {
        alert(`Failed to load template: ${error.message}`);
    }
}

async function saveTemplate() {
    const name = document.getElementById('template-name').value.trim();
    if (!name) {
        alert('Please enter a template name');
        return;
    }
    
    const lines = Array.from(document.querySelectorAll('.line-input'))
        .map(input => input.value.trim())
        .filter(line => line.length > 0);
    
    if (lines.length === 0) {
        alert('Please enter at least one line');
        return;
    }
    
    const fontSize = document.getElementById('font-size').value;
    
    try {
        const response = await fetch(`${API_BASE}/templates`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                name: name,
                lines: lines,
                font_size: fontSize
            })
        });
        
        if (response.ok) {
            document.getElementById('template-name').value = '';
            loadTemplates();
            alert('Template saved!');
        } else {
            const error = await response.json();
            alert(`Failed to save template: ${error.detail}`);
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

// QR Code Functions
async function handleQRCodeSubmit(e) {
    e.preventDefault();
    const data = document.getElementById('qrcode-data').value.trim();
    const labelText = document.getElementById('qrcode-label').value.trim();
    
    if (!data) {
        alert('Please enter QR code data');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/qrcode`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                data: data,
                label_text: labelText || null
            })
        });
        
        if (response.ok) {
            const result = await response.json();
            alert(result.message);
            document.getElementById('qrcode-form').reset();
            loadHistory();
        } else {
            const error = await response.json();
            alert(`QR code print failed: ${error.detail}`);
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

// History Functions
async function loadHistory() {
    try {
        const response = await fetch(`${API_BASE}/history`);
        const history = await response.json();
        renderHistory(history);
    } catch (error) {
        console.error('Failed to load history:', error);
    }
}

function renderHistory(history) {
    const list = document.getElementById('history-list');
    const empty = document.getElementById('history-empty');
    
    if (history.length === 0) {
        empty.style.display = 'block';
        list.innerHTML = '';
        return;
    }
    
    empty.style.display = 'none';
    list.innerHTML = history.slice().reverse().map(entry => `
        <li class="history-item">
            <div class="${entry.success ? 'history-success' : 'history-error'}">
                ${entry.success ? '✓ Success' : '✗ Failed'}
            </div>
            <div class="job-lines">
                ${entry.jobs.map(job => 
                    job.lines.map(line => `<div>${escapeHtml(line)}</div>`).join('')
                ).join('')}
            </div>
            ${entry.error ? `<div style="color: #e74c3c; margin-top: 5px;">${escapeHtml(entry.error)}</div>` : ''}
            <div class="history-time">${new Date(entry.printed_at).toLocaleString()}</div>
        </li>
    `).join('');
}

// Prepreview Functions
async function generatePrepreview() {
    console.log('generatePrepreview called');
    const lineCount = parseInt(document.getElementById('prepreview-line-count').value);
    console.log('Line count:', lineCount);
    
    // Check if queue has jobs
    const queueResponse = await fetch(`${API_BASE}/jobs`);
    const queueData = await queueResponse.json();
    console.log('Queue data:', queueData);
    if (!queueData.jobs || queueData.jobs.length === 0) {
        alert('No jobs in queue. Please add jobs first.');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/jobs/prepreview`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                line_count: lineCount
            })
        });
        
        console.log('Response status:', response.status);
        
        if (response.ok) {
            const blob = await response.blob();
            console.log('Blob type:', blob.type, 'size:', blob.size);
            const url = URL.createObjectURL(blob);
            const prepreviewImg = document.getElementById('prepreview-img');
            const prepreviewImage = document.getElementById('prepreview-image');
            const prepreviewEmpty = document.getElementById('prepreview-empty');
            
            if (!prepreviewImg || !prepreviewImage || !prepreviewEmpty) {
                console.error('Prepreview elements not found');
                alert('Prepreview elements not found');
                return;
            }
            
            prepreviewImg.src = url;
            prepreviewImage.style.display = 'block';
            prepreviewEmpty.style.display = 'none';
            prepreviewImage.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        } else {
            const error = await response.json();
            console.error('Prepreview error:', error);
            alert(`Prepreview generation failed: ${error.detail}`);
        }
    } catch (error) {
        console.error('Prepreview exception:', error);
        alert(`Error: ${error.message}`);
    }
}

// Printer Info
async function getPrinterInfo() {
    try {
        const response = await fetch(`${API_BASE}/printer/info`);
        if (response.ok) {
            const data = await response.json();
            // Display in alert with formatted text
            const infoText = data.info || 'No info available';
            alert(infoText);
        } else {
            const error = await response.json();
            alert(`Failed to get printer info: ${error.detail}`);
        }
    } catch (error) {
        alert(`Error: ${error.message}`);
    }
}

// Utility
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

