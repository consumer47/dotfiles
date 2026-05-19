import json
from pathlib import Path
from typing import List, Optional
from datetime import datetime
from models import Template, TemplateCreate, FontSize


class TemplateManager:
    def __init__(self, storage_path: str = "/app/data/templates.json"):
        self.storage_path = Path(storage_path)
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        self._load_templates()
    
    def _load_templates(self):
        """Load templates from JSON file"""
        if self.storage_path.exists():
            try:
                with open(self.storage_path, 'r') as f:
                    data = json.load(f)
                    self.templates = {
                        tid: Template(**{**t, "created_at": datetime.fromisoformat(t["created_at"])})
                        for tid, t in data.items()
                    }
            except Exception:
                self.templates = {}
        else:
            self.templates = {}
    
    def _save_templates(self):
        """Save templates to JSON file"""
        data = {
            tid: {
                **template.dict(),
                "created_at": template.created_at.isoformat()
            }
            for tid, template in self.templates.items()
        }
        with open(self.storage_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def create_template(self, template_data: TemplateCreate) -> Template:
        """Create a new template"""
        template_id = f"tpl_{len(self.templates)}_{datetime.now().timestamp()}"
        template = Template(
            id=template_id,
            name=template_data.name,
            lines=template_data.lines,
            font_size=template_data.font_size,
            created_at=datetime.now()
        )
        self.templates[template_id] = template
        self._save_templates()
        return template
    
    def get_template(self, template_id: str) -> Optional[Template]:
        """Get a template by ID"""
        return self.templates.get(template_id)
    
    def list_templates(self) -> List[Template]:
        """List all templates"""
        return list(self.templates.values())
    
    def delete_template(self, template_id: str) -> bool:
        """Delete a template"""
        if template_id in self.templates:
            del self.templates[template_id]
            self._save_templates()
            return True
        return False

